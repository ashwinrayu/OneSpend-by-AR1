import { query, pool } from '../config/db.js';

// GET /api/transactions
export const getTransactions = async (req, res) => {
  try {
    const { category, type, startDate, endDate, limit = 100, offset = 0 } = req.query;

    let queryText = `
      SELECT id, title, amount, type, category, payment_method, timestamp, notes, updated_at
      FROM transactions
      WHERE user_id = $1 AND is_deleted = FALSE
    `;
    const params = [req.userId];
    let paramIndex = 2;

    if (category) {
      queryText += ` AND category = $${paramIndex}`;
      params.push(category);
      paramIndex++;
    }

    if (type) {
      queryText += ` AND type = $${paramIndex}`;
      params.push(type.toLowerCase());
      paramIndex++;
    }

    if (startDate) {
      queryText += ` AND timestamp >= $${paramIndex}`;
      params.push(new Date(startDate));
      paramIndex++;
    }

    if (endDate) {
      queryText += ` AND timestamp <= $${paramIndex}`;
      params.push(new Date(endDate));
      paramIndex++;
    }

    queryText += ` ORDER BY timestamp DESC LIMIT $${paramIndex} OFFSET $${paramIndex + 1}`;
    params.push(parseInt(limit, 10), parseInt(offset, 10));

    const result = await query(queryText, params);

    return res.status(200).json({
      count: result.rows.length,
      transactions: result.rows,
    });
  } catch (err) {
    console.error('Error fetching transactions:', err);
    return res.status(500).json({ error: 'Failed to retrieve transactions.', details: err.message });
  }
};

// POST /api/transactions
export const createTransaction = async (req, res) => {
  try {
    const { id, title, amount, type, category, payment_method, timestamp, notes } = req.body;

    if (!title || amount === undefined || !type || !category) {
      return res.status(400).json({
        error: 'title, amount, type, and category are required fields.',
      });
    }

    const txId = id || crypto.randomUUID();
    const txTime = timestamp ? new Date(timestamp) : new Date();

    const result = await query(
      `INSERT INTO transactions
       (id, user_id, title, amount, type, category, payment_method, timestamp, notes, is_deleted, updated_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, FALSE, CURRENT_TIMESTAMP)
       ON CONFLICT (id) DO UPDATE SET
         title = EXCLUDED.title,
         amount = EXCLUDED.amount,
         type = EXCLUDED.type,
         category = EXCLUDED.category,
         payment_method = EXCLUDED.payment_method,
         timestamp = EXCLUDED.timestamp,
         notes = EXCLUDED.notes,
         is_deleted = FALSE,
         updated_at = CURRENT_TIMESTAMP
       RETURNING id, title, amount, type, category, payment_method, timestamp, notes, updated_at`,
      [
        txId,
        req.userId,
        title,
        parseFloat(amount),
        type.toLowerCase(),
        category,
        payment_method || 'UPI',
        txTime,
        notes || null,
      ]
    );

    return res.status(201).json({
      message: 'Transaction saved successfully.',
      transaction: result.rows[0],
    });
  } catch (err) {
    console.error('Error creating transaction:', err);
    return res.status(500).json({ error: 'Failed to create transaction.', details: err.message });
  }
};

// PUT /api/transactions/:id
export const updateTransaction = async (req, res) => {
  try {
    const { id } = req.params;
    const { title, amount, type, category, payment_method, timestamp, notes } = req.body;

    // Check ownership
    const existing = await query(
      'SELECT id FROM transactions WHERE id = $1 AND user_id = $2 AND is_deleted = FALSE',
      [id, req.userId]
    );

    if (existing.rows.length === 0) {
      return res.status(404).json({ error: 'Transaction not found or access denied.' });
    }

    const updateResult = await query(
      `UPDATE transactions
       SET title = COALESCE($1, title),
           amount = COALESCE($2, amount),
           type = COALESCE($3, type),
           category = COALESCE($4, category),
           payment_method = COALESCE($5, payment_method),
           timestamp = COALESCE($6, timestamp),
           notes = COALESCE($7, notes),
           updated_at = CURRENT_TIMESTAMP
       WHERE id = $8 AND user_id = $9
       RETURNING id, title, amount, type, category, payment_method, timestamp, notes, updated_at`,
      [
        title,
        amount !== undefined ? parseFloat(amount) : null,
        type ? type.toLowerCase() : null,
        category,
        payment_method,
        timestamp ? new Date(timestamp) : null,
        notes,
        id,
        req.userId,
      ]
    );

    return res.status(200).json({
      message: 'Transaction updated successfully.',
      transaction: updateResult.rows[0],
    });
  } catch (err) {
    console.error('Error updating transaction:', err);
    return res.status(500).json({ error: 'Failed to update transaction.', details: err.message });
  }
};

// DELETE /api/transactions/:id
export const deleteTransaction = async (req, res) => {
  try {
    const { id } = req.params;

    // Mark as deleted for sync consistency
    const result = await query(
      `UPDATE transactions
       SET is_deleted = TRUE, updated_at = CURRENT_TIMESTAMP
       WHERE id = $1 AND user_id = $2
       RETURNING id`,
      [id, req.userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Transaction not found or access denied.' });
    }

    return res.status(200).json({
      message: 'Transaction removed successfully.',
      id,
    });
  } catch (err) {
    console.error('Error deleting transaction:', err);
    return res.status(500).json({ error: 'Failed to delete transaction.', details: err.message });
  }
};

// POST /api/sync (Batch Delta-Sync for Offline-First Clients)
export const syncTransactions = async (req, res) => {
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
            `UPDATE transactions
             SET is_deleted = TRUE, updated_at = CURRENT_TIMESTAMP
             WHERE id = $1 AND user_id = $2`,
            [item.id, req.userId]
          );
        } else {
          await client.query(
            `INSERT INTO transactions
             (id, user_id, title, amount, type, category, payment_method, timestamp, notes, is_deleted, updated_at)
             VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, FALSE, CURRENT_TIMESTAMP)
             ON CONFLICT (id) DO UPDATE SET
               title = EXCLUDED.title,
               amount = EXCLUDED.amount,
               type = EXCLUDED.type,
               category = EXCLUDED.category,
               payment_method = EXCLUDED.payment_method,
               timestamp = EXCLUDED.timestamp,
               notes = EXCLUDED.notes,
               is_deleted = FALSE,
               updated_at = CURRENT_TIMESTAMP`,
            [
              item.id,
              req.userId,
              item.title,
              parseFloat(item.amount),
              item.type ? item.type.toLowerCase() : 'expense',
              item.category || 'Other',
              item.paymentMethod || 'UPI',
              new Date(item.timestamp),
              item.notes || null,
            ]
          );
        }
      }
    }

    await client.query('COMMIT');

    // 2. Fetch server changes modified since lastSyncedAt
    let serverChangesQuery = `
      SELECT id, title, amount, type, category, payment_method, timestamp, notes, is_deleted, updated_at
      FROM transactions
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
      message: 'Sync completed successfully.',
      syncedAt: syncStartTime.toISOString(),
      appliedClientChangesCount: clientChanges.length,
      serverChanges: serverResult.rows,
    });
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Error during transaction sync:', err);
    return res.status(500).json({ error: 'Sync failed.', details: err.message });
  } finally {
    client.release();
  }
};
