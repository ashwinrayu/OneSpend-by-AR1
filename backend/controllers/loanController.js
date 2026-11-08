import { query, pool } from '../config/db.js';

// GET /api/loans
export const getLoans = async (req, res) => {
  try {
    const result = await query(
      `SELECT id, name, lender, total_amount, interest_rate, tenure_months,
              monthly_emi, paid_emis, paid_amount, start_date, due_day,
              category, payment_method, is_closed, notes, interest_type,
              last_payment_date, is_deleted, updated_at
       FROM loans
       WHERE user_id = $1 AND is_deleted = FALSE
       ORDER BY is_closed ASC, due_day ASC`,
      [req.userId]
    );

    return res.status(200).json({
      loans: result.rows,
      count: result.rowCount,
    });
  } catch (err) {
    console.error('Error fetching loans:', err);
    return res.status(500).json({ error: 'Failed to retrieve loans.' });
  }
};

// POST /api/loans
export const createLoan = async (req, res) => {
  try {
    const {
      id,
      name,
      lender = '',
      totalAmount,
      interestRate = 0,
      tenureMonths,
      monthlyEmi,
      paidEmis = 0,
      paidAmount = 0,
      startDate = new Date(),
      dueDay = 5,
      category = 'Personal',
      paymentMethod = 'Bank Transfer',
      isClosed = false,
      notes = null,
      interestType = 'reducing',
      lastPaymentDate = null,
    } = req.body;

    if (!id || !name || !totalAmount || !tenureMonths || !monthlyEmi) {
      return res.status(400).json({ error: 'Missing required loan fields.' });
    }

    const result = await query(
      `INSERT INTO loans
       (id, user_id, name, lender, total_amount, interest_rate, tenure_months,
        monthly_emi, paid_emis, paid_amount, start_date, due_day, category,
        payment_method, is_closed, notes, interest_type, last_payment_date, is_deleted, updated_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, FALSE, CURRENT_TIMESTAMP)
       RETURNING *`,
      [
        id,
        req.userId,
        name,
        lender,
        parseFloat(totalAmount),
        parseFloat(interestRate),
        parseInt(tenureMonths),
        parseFloat(monthlyEmi),
        parseInt(paidEmis),
        parseFloat(paidAmount),
        new Date(startDate),
        parseInt(dueDay),
        category,
        paymentMethod,
        Boolean(isClosed),
        notes,
        interestType,
        lastPaymentDate ? new Date(lastPaymentDate) : null,
      ]
    );

    return res.status(201).json({
      message: 'Loan plan created.',
      loan: result.rows[0],
    });
  } catch (err) {
    console.error('Error creating loan:', err);
    return res.status(500).json({ error: 'Failed to create loan.' });
  }
};

// PUT /api/loans/:id
export const updateLoan = async (req, res) => {
  try {
    const { id } = req.params;
    const {
      name,
      lender,
      totalAmount,
      interestRate,
      tenureMonths,
      monthlyEmi,
      paidEmis,
      paidAmount,
      startDate,
      dueDay,
      category,
      paymentMethod,
      isClosed,
      notes,
      interestType,
      lastPaymentDate,
    } = req.body;

    const result = await query(
      `UPDATE loans
       SET name = COALESCE($1, name),
           lender = COALESCE($2, lender),
           total_amount = COALESCE($3, total_amount),
           interest_rate = COALESCE($4, interest_rate),
           tenure_months = COALESCE($5, tenure_months),
           monthly_emi = COALESCE($6, monthly_emi),
           paid_emis = COALESCE($7, paid_emis),
           paid_amount = COALESCE($8, paid_amount),
           start_date = COALESCE($9, start_date),
           due_day = COALESCE($10, due_day),
           category = COALESCE($11, category),
           payment_method = COALESCE($12, payment_method),
           is_closed = COALESCE($13, is_closed),
           notes = COALESCE($14, notes),
           interest_type = COALESCE($15, interest_type),
           last_payment_date = COALESCE($16, last_payment_date),
           updated_at = CURRENT_TIMESTAMP
       WHERE id = $17 AND user_id = $18
       RETURNING *`,
      [
        name,
        lender,
        totalAmount !== undefined ? parseFloat(totalAmount) : null,
        interestRate !== undefined ? parseFloat(interestRate) : null,
        tenureMonths !== undefined ? parseInt(tenureMonths) : null,
        monthlyEmi !== undefined ? parseFloat(monthlyEmi) : null,
        paidEmis !== undefined ? parseInt(paidEmis) : null,
        paidAmount !== undefined ? parseFloat(paidAmount) : null,
        startDate ? new Date(startDate) : null,
        dueDay !== undefined ? parseInt(dueDay) : null,
        category,
        paymentMethod,
        isClosed !== undefined ? Boolean(isClosed) : null,
        notes,
        interestType,
        lastPaymentDate ? new Date(lastPaymentDate) : null,
        id,
        req.userId,
      ]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({ error: 'Loan not found.' });
    }

    return res.status(200).json({
      message: 'Loan updated successfully.',
      loan: result.rows[0],
    });
  } catch (err) {
    console.error('Error updating loan:', err);
    return res.status(500).json({ error: 'Failed to update loan.' });
  }
};

// DELETE /api/loans/:id (Soft-delete for delta-sync)
export const deleteLoan = async (req, res) => {
  try {
    const { id } = req.params;
    const result = await query(
      `UPDATE loans
       SET is_deleted = TRUE, updated_at = CURRENT_TIMESTAMP
       WHERE id = $1 AND user_id = $2
       RETURNING id`,
      [id, req.userId]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({ error: 'Loan not found.' });
    }

    return res.status(200).json({ message: 'Loan deleted successfully.', id });
  } catch (err) {
    console.error('Error deleting loan:', err);
    return res.status(500).json({ error: 'Failed to delete loan.' });
  }
};

// POST /api/loans/sync (Batch Delta-Sync for Offline-First Clients)
export const syncLoans = async (req, res) => {
  const client = await pool.connect();
  try {
    const { clientChanges = [], lastSyncedAt } = req.body;
    const syncStartTime = new Date();

    await client.query('BEGIN');

    // 1. Ingest client mutations
    if (Array.isArray(clientChanges) && clientChanges.length > 0) {
      for (const item of clientChanges) {
        if (item.isDeleted) {
          await client.query(
            `UPDATE loans
             SET is_deleted = TRUE, updated_at = CURRENT_TIMESTAMP
             WHERE id = $1 AND user_id = $2`,
            [item.id, req.userId]
          );
        } else {
          await client.query(
            `INSERT INTO loans
             (id, user_id, name, lender, total_amount, interest_rate, tenure_months,
              monthly_emi, paid_emis, paid_amount, start_date, due_day, category,
              payment_method, is_closed, notes, interest_type, last_payment_date, is_deleted, updated_at)
             VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, FALSE, CURRENT_TIMESTAMP)
             ON CONFLICT (id) DO UPDATE SET
               name = EXCLUDED.name,
               lender = EXCLUDED.lender,
               total_amount = EXCLUDED.total_amount,
               interest_rate = EXCLUDED.interest_rate,
               tenure_months = EXCLUDED.tenure_months,
               monthly_emi = EXCLUDED.monthly_emi,
               paid_emis = EXCLUDED.paid_emis,
               paid_amount = EXCLUDED.paid_amount,
               start_date = EXCLUDED.start_date,
               due_day = EXCLUDED.due_day,
               category = EXCLUDED.category,
               payment_method = EXCLUDED.payment_method,
               is_closed = EXCLUDED.is_closed,
               notes = EXCLUDED.notes,
               interest_type = EXCLUDED.interest_type,
               last_payment_date = EXCLUDED.last_payment_date,
               is_deleted = FALSE,
               updated_at = CURRENT_TIMESTAMP`,
            [
              item.id,
              req.userId,
              item.name,
              item.lender || '',
              parseFloat(item.totalAmount),
              parseFloat(item.interestRate || 0),
              parseInt(item.tenureMonths),
              parseFloat(item.monthlyEmi),
              parseInt(item.paidEmis || 0),
              parseFloat(item.paidAmount || 0),
              new Date(item.startDate || Date.now()),
              parseInt(item.dueDay || 5),
              item.category || 'Personal',
              item.paymentMethod || 'Bank Transfer',
              Boolean(item.isClosed),
              item.notes || null,
              item.interestType || 'reducing',
              item.lastPaymentDate ? new Date(item.lastPaymentDate) : null,
            ]
          );
        }
      }
    }

    await client.query('COMMIT');

    // 2. Fetch server changes modified since lastSyncedAt
    let serverChangesQuery = `
      SELECT id, name, lender, total_amount, interest_rate, tenure_months,
             monthly_emi, paid_emis, paid_amount, start_date, due_day,
             category, payment_method, is_closed, notes, interest_type,
             last_payment_date, is_deleted, updated_at
      FROM loans
      WHERE user_id = $1
    `;
    const params = [req.userId];

    if (lastSyncedAt) {
      serverChangesQuery += ` AND updated_at > $2`;
      params.push(new Date(lastSyncedAt));
    }

    serverChangesQuery += ` ORDER BY updated_at ASC`;
    const serverResult = await query(serverChangesQuery, params);

    return res.status(200).json({
      message: 'Loan sync completed successfully.',
      syncedAt: syncStartTime.toISOString(),
      appliedClientChangesCount: clientChanges.length,
      serverChanges: serverResult.rows,
    });
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Error during loan sync:', err);
    return res.status(500).json({ error: 'Loan sync failed.', details: err.message });
  } finally {
    client.release();
  }
};
