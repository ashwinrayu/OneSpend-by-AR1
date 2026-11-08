import express from 'express';
import {
  getLoans,
  createLoan,
  updateLoan,
  deleteLoan,
  syncLoans,
} from '../controllers/loanController.js';
import { authMiddleware } from '../middleware/auth.js';

const router = express.Router();

// All loan routes are protected by JWT auth
router.use(authMiddleware);

router.get('/', getLoans);
router.post('/', createLoan);
router.put('/:id', updateLoan);
router.delete('/:id', deleteLoan);
router.post('/sync', syncLoans);

export default router;

