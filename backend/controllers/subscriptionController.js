import { query, pool } from '../config/db.js';

// GET /api/subscriptions
export const getSubscriptions = async (req, res) => {
  try {
    const result = await query(
      `SELECT id, name, amount, billing_cycle, category, next_billing_date,
              payment_method, is_active, is_deleted, updated_at
       FROM subscriptions
       WHERE user_id = $1 AND is_deleted = FALSE
       ORDER BY next_billing_date ASC`,
      [req.userId]
    );

    return res.status(200).json({
      subscriptions: result.rows,
      count: result.rowCount,
    });
  } catch (err) {
    console.error('Error fetching subscriptions:', err);
    return res.status(500).json({ error: 'Failed to retrieve subscriptions.' });
  }
};

// POST /api/subscriptions
export const createSubscription = async (req, res) => {
  try {
    const {
      id,
      name,
      amount,
      billingCycle = 'Monthly',
      category = 'Bills',
      nextBillingDate = new Date(),
      paymentMethod = 'UPI',
      isActive = true,
    } = req.body;

    if (!id || !name || amount === undefined) {
      return res.status(400).json({ error: 'Missing required subscription fields.' });
    }

    const result = await query(
      `INSERT INTO subscriptions
       (id, user_id, name, amount, billing_cycle, category, next_billing_date,
        payment_method, is_active, is_deleted, updated_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, FALSE, CURRENT_TIMESTAMP)
       RETURNING *`,
      [
        id,
        req.userId,
        name,
        parseFloat(amount),
        billingCycle,
        category,
        new Date(nextBillingDate),
        paymentMethod,
        Boolean(isActive),
      ]
    );

    return res.status(201).json({
      message: 'Subscription created successfully.',
      subscription: result.rows[0],
    });
  } catch (err) {
    console.error('Error creating subscription:', err);
    return res.status(500).json({ error: 'Failed to create subscription.' });
  }
};

// PUT /api/subscriptions/:id
export const updateSubscription = async (req, res) => {
  try {
    const { id } = req.params;
    const {
      name,
      amount,
      billingCycle,
      category,
      nextBillingDate,
      paymentMethod,
      isActive,
    } = req.body;

    const result = await query(
      `UPDATE subscriptions
       SET name = COALESCE($1, name),
           amount = COALESCE($2, amount),
           billing_cycle = COALESCE($3, billing_cycle),
           category = COALESCE($4, category),
           next_billing_date = COALESCE($5, next_billing_date),
           payment_method = COALESCE($6, payment_method),
           is_active = COALESCE($7, is_active),
           updated_at = CURRENT_TIMESTAMP
       WHERE id = $8 AND user_id = $9
       RETURNING *`,
      [
        name,
        amount !== undefined ? parseFloat(amount) : null,
        billingCycle,
        category,
        nextBillingDate ? new Date(nextBillingDate) : null,
        paymentMethod,
        isActive !== undefined ? Boolean(isActive) : null,
        id,
        req.userId,
      ]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({ error: 'Subscription not found.' });
    }

    return res.status(200).json({
      message: 'Subscription updated successfully.',
      subscription: result.rows[0],
    });
  } catch (err) {
    console.error('Error updating subscription:', err);
    return res.status(500).json({ error: 'Failed to update subscription.' });
  }
};

// DELETE /api/subscriptions/:id (Soft-delete for delta-sync)
export const deleteSubscription = async (req, res) => {
  try {
    const { id } = req.params;
    const result = await query(
      `UPDATE subscriptions
       SET is_deleted = TRUE, updated_at = CURRENT_TIMESTAMP
       WHERE id = $1 AND user_id = $2
       RETURNING id`,
      [id, req.userId]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({ error: 'Subscription not found.' });
    }

    return res.status(200).json({ message: 'Subscription deleted successfully.', id });
  } catch (err) {
    console.error('Error deleting subscription:', err);
    return res.status(500).json({ error: 'Failed to delete subscription.' });
  }
};

// POST /api/subscriptions/sync (Batch Delta-Sync for Offline-First Clients)
export const syncSubscriptions = async (req, res) => {
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
            `UPDATE subscriptions
             SET is_deleted = TRUE, updated_at = CURRENT_TIMESTAMP
             WHERE id = $1 AND user_id = $2`,
            [item.id, req.userId]
          );
        } else {
          await client.query(
            `INSERT INTO subscriptions
             (id, user_id, name, amount, billing_cycle, category, next_billing_date,
              payment_method, is_active, is_deleted, updated_at)
             VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, FALSE, CURRENT_TIMESTAMP)
             ON CONFLICT (id) DO UPDATE SET
               name = EXCLUDED.name,
               amount = EXCLUDED.amount,
               billing_cycle = EXCLUDED.billing_cycle,
               category = EXCLUDED.category,
               next_billing_date = EXCLUDED.next_billing_date,
               payment_method = EXCLUDED.payment_method,
               is_active = EXCLUDED.is_active,
               is_deleted = FALSE,
               updated_at = CURRENT_TIMESTAMP`,
            [
              item.id,
              req.userId,
              item.name,
              parseFloat(item.amount),
              item.billingCycle || 'Monthly',
              item.category || 'Bills',
              new Date(item.nextBillingDate || Date.now()),
              item.paymentMethod || 'UPI',
              item.isActive !== undefined ? Boolean(item.isActive) : true,
            ]
          );
        }
      }
    }

    await client.query('COMMIT');

    // 2. Fetch server changes modified since lastSyncedAt
    let serverChangesQuery = `
      SELECT id, name, amount, billing_cycle, category, next_billing_date,
             payment_method, is_active, is_deleted, updated_at
      FROM subscriptions
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
      message: 'Subscription sync completed successfully.',
      syncedAt: syncStartTime.toISOString(),
      appliedClientChangesCount: clientChanges.length,
      serverChanges: serverResult.rows,
    });
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Error during subscription sync:', err);
    return res.status(500).json({ error: 'Subscription sync failed.', details: err.message });
  } finally {
    client.release();
  }
};

