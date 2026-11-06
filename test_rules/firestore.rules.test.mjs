import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { after, before, beforeEach, describe, it } from 'node:test';
import { fileURLToPath } from 'node:url';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  Timestamp,
  collection,
  deleteDoc,
  deleteField,
  doc,
  getDoc,
  getDocs,
  increment,
  orderBy,
  query,
  setDoc,
  updateDoc,
  writeBatch,
} from 'firebase/firestore';

const __dirname = dirname(fileURLToPath(import.meta.url));
const RULES_PATH = resolve(__dirname, '..', 'firestore.rules');
const PROJECT_ID = 'demo-so-thu-chi';

const ALICE_UID = 'user_alice_123';
const BOB_UID = 'user_bob_456';

const t0 = Timestamp.fromDate(new Date('2026-03-01T08:00:00.000Z'));
const t1 = Timestamp.fromDate(new Date('2026-03-02T09:30:00.000Z'));
const t2 = Timestamp.fromDate(new Date('2026-03-03T10:15:00.000Z'));

function parseEmulatorHostPort() {
  const envHost = process.env.FIRESTORE_EMULATOR_HOST;
  if (!envHost) {
    return { host: '127.0.0.1', port: 8080 };
  }
  const [host, portStr] = envHost.split(':');
  return { host, port: Number(portStr) };
}

function validUserProfile(uid = ALICE_UID) {
  return {
    uid,
    email: 'alice@sothuchi.vn',
    displayName: 'Alice Nguyễn',
    photoUrl: 'https://example.com/avatar.png',
    defaultCurrency: 'VND',
    locale: 'vi',
    createdAt: t0,
    updatedAt: t0,
    deletedAt: null,
  };
}

function validAccount(id = 'acc_cash') {
  return {
    id,
    name: 'Tiền mặt',
    type: 'cash',
    balance: 1000000,
    currency: 'VND',
    icon: 'cash',
    color: 0xff0d7c66,
    archived: false,
    createdAt: t0,
    updatedAt: t0,
    deletedAt: null,
  };
}

function validCategory(id = 'default_food') {
  return {
    id,
    name: 'Ăn uống',
    type: 'expense',
    icon: 'food',
    color: 0xffc0352b,
    parentId: null,
    isDefault: true,
    createdAt: t0,
    updatedAt: t0,
    deletedAt: null,
  };
}

function validTransaction(id = 'tx_1') {
  return {
    id,
    amount: 50000,
    currency: 'VND',
    type: 'expense',
    accountId: 'acc_cash',
    toAccountId: null,
    categoryId: 'default_food',
    note: 'Phở bò buổi sáng',
    date: t0,
    tags: ['breakfast', 'food'],
    createdAt: t0,
    updatedAt: t0,
    deletedAt: null,
  };
}

function validBudget(id = 'budget_overall_2026_03') {
  return {
    id,
    categoryId: null,
    amount: 10000000,
    currency: 'VND',
    period: 'month',
    startDate: t0,
    alertThreshold: 80,
    createdAt: t0,
    updatedAt: t0,
    deletedAt: null,
  };
}

function validDebt(id = 'debt_1') {
  return {
    id,
    personName: 'Nguyễn Văn Nam',
    phoneNumber: '0901234567',
    type: 'lent',
    amount: 1500000,
    remainingAmount: 1500000,
    currency: 'VND',
    dueDate: t2,
    accountId: 'acc_cash',
    note: 'Vay tiền mua vé máy bay',
    createdAt: t0,
    updatedAt: t0,
    deletedAt: null,
  };
}

function validRecurring(id = 'rec_1') {
  return {
    id,
    title: 'Tiền thuê nhà',
    amount: 5000000,
    currency: 'VND',
    type: 'expense',
    frequency: 'monthly',
    dayOfMonth: 5,
    categoryId: 'default_housing',
    accountId: 'acc_bank',
    note: 'Chuyển khoản ngày 5 hàng tháng',
    isActive: true,
    nextDueDate: t1,
    lastExecutedDate: null,
    createdAt: t0,
    updatedAt: t0,
    deletedAt: null,
  };
}

function validSavingsGoal(id = 'goal_1') {
  return {
    id,
    name: 'Mua xe máy mới',
    targetAmount: 40000000,
    currentAmount: 10000000,
    currency: 'VND',
    deadline: t2,
    accountId: 'acc_bank',
    icon: 'motorcycle',
    color: 0xff0d7c66,
    note: 'Mục tiêu mua xe trước quý 4',
    createdAt: t0,
    updatedAt: t0,
    deletedAt: null,
  };
}

function validLedger(id = 'ledger_1') {
  return {
    id,
    name: 'Sổ chi tiêu gia đình',
    type: 'family',
    currency: 'VND',
    icon: 'family',
    color: 0xff0d7c66,
    isDefault: false,
    description: 'Quản lý thu chi sinh hoạt gia đình',
    sharedMemberEmails: ['alice@sothuchi.vn', 'bob@sothuchi.vn'],
    createdAt: t0,
    updatedAt: t0,
    deletedAt: null,
  };
}

let testEnv;

describe('Sổ Thu Chi — Firestore Security Rules', () => {
  before(async () => {
    const { host, port } = parseEmulatorHostPort();
    testEnv = await initializeTestEnvironment({
      projectId: PROJECT_ID,
      firestore: {
        host,
        port,
        rules: readFileSync(RULES_PATH, 'utf8'),
      },
    });
  });

  beforeEach(async () => {
    await testEnv.clearFirestore();
  });

  after(async () => {
    if (testEnv) {
      await testEnv.cleanup();
    }
  });

  it('denies unauthenticated access and unknown root collections (default deny)', async () => {
    const unauthDb = testEnv.unauthenticatedContext().firestore();
    const aliceDb = testEnv.authenticatedContext(ALICE_UID).firestore();

    await assertFails(getDoc(doc(unauthDb, `users/${ALICE_UID}`)));
    await assertFails(
      setDoc(doc(unauthDb, `users/${ALICE_UID}`), validUserProfile()),
    );
    await assertFails(
      getDocs(collection(unauthDb, `users/${ALICE_UID}/transactions`)),
    );

    // Default deny on any collection outside /users/{uid}
    await assertFails(setDoc(doc(aliceDb, 'public_configs/app'), { ok: true }));
    await assertFails(getDoc(doc(aliceDb, 'public_configs/app')));
  });

  it('allows owner CRUD, queries, and full account data deletion across all collections', async () => {
    const aliceDb = testEnv.authenticatedContext(ALICE_UID).firestore();

    // 1. User profile (preference merge bootstrap before full profile, then full profile merge)
    const userRef = doc(aliceDb, `users/${ALICE_UID}`);
    await assertSucceeds(
      setDoc(
        userRef,
        { defaultCurrency: 'USD', locale: 'en', updatedAt: t0 },
        { merge: true },
      ),
    );
    await assertSucceeds(
      setDoc(userRef, validUserProfile(ALICE_UID), { merge: true }),
    );
    const snap = await assertSucceeds(getDoc(userRef));
    assert.equal(snap.exists(), true);

    // 2. Accounts, Categories, Transactions, Budgets
    const accRef = doc(aliceDb, `users/${ALICE_UID}/accounts/acc_cash`);
    const bankRef = doc(aliceDb, `users/${ALICE_UID}/accounts/acc_bank`);
    const catRef = doc(aliceDb, `users/${ALICE_UID}/categories/default_food`);
    const txRef = doc(aliceDb, `users/${ALICE_UID}/transactions/tx_1`);
    const transferRef = doc(aliceDb, `users/${ALICE_UID}/transactions/tx_2`);
    const budgetRef = doc(aliceDb, `users/${ALICE_UID}/budgets/b_1`);

    await assertSucceeds(setDoc(accRef, validAccount('acc_cash')));
    await assertSucceeds(
      setDoc(bankRef, { ...validAccount('acc_bank'), type: 'bank' }),
    );
    await assertSucceeds(setDoc(catRef, validCategory('default_food')));
    await assertSucceeds(setDoc(txRef, validTransaction('tx_1')));
    await assertSucceeds(
      setDoc(transferRef, {
        ...validTransaction('tx_2'),
        type: 'transfer',
        accountId: 'acc_cash',
        toAccountId: 'acc_bank',
        categoryId: 'system_transfer',
        date: t1,
      }),
    );
    await assertSucceeds(setDoc(budgetRef, validBudget('b_1')));

    // 3. Verify transaction orderBy('date', 'desc') query works for owner
    const txQuery = query(
      collection(aliceDb, `users/${ALICE_UID}/transactions`),
      orderBy('date', 'desc'),
    );
    const txSnap = await assertSucceeds(getDocs(txQuery));
    assert.equal(txSnap.size, 2);

    // 4. Verify deleteAccountAndAllData() hard deletes succeed for owner
    await assertSucceeds(deleteDoc(txRef));
    await assertSucceeds(deleteDoc(transferRef));
    await assertSucceeds(deleteDoc(budgetRef));
    await assertSucceeds(deleteDoc(accRef));
    await assertSucceeds(deleteDoc(bankRef));
    await assertSucceeds(deleteDoc(catRef));
    await assertSucceeds(deleteDoc(userRef));
  });

  it('denies cross-user read, create, update, query, and delete', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      const adminDb = ctx.firestore();
      await setDoc(doc(adminDb, `users/${ALICE_UID}`), validUserProfile());
      await setDoc(
        doc(adminDb, `users/${ALICE_UID}/accounts/acc_cash`),
        validAccount(),
      );
      await setDoc(
        doc(adminDb, `users/${ALICE_UID}/transactions/tx_1`),
        validTransaction(),
      );
    });

    const bobDb = testEnv.authenticatedContext(BOB_UID).firestore();

    await assertFails(getDoc(doc(bobDb, `users/${ALICE_UID}`)));
    await assertFails(
      getDocs(collection(bobDb, `users/${ALICE_UID}/transactions`)),
    );
    await assertFails(
      setDoc(
        doc(bobDb, `users/${ALICE_UID}/accounts/hijack`),
        validAccount('hijack'),
      ),
    );
    await assertFails(
      updateDoc(doc(bobDb, `users/${ALICE_UID}/accounts/acc_cash`), {
        archived: true,
        updatedAt: t1,
      }),
    );
    await assertFails(
      deleteDoc(doc(bobDb, `users/${ALICE_UID}/transactions/tx_1`)),
    );
    await assertFails(deleteDoc(doc(bobDb, `users/${ALICE_UID}`)));

    // Owner cannot spoof uid inside their own profile document
    const aliceDb = testEnv.authenticatedContext(ALICE_UID).firestore();
    await assertFails(
      setDoc(doc(aliceDb, `users/${ALICE_UID}`), {
        ...validUserProfile(BOB_UID),
      }),
    );
  });

  it('rejects float minor-unit amounts/balances and non-positive amounts', async () => {
    const aliceDb = testEnv.authenticatedContext(ALICE_UID).firestore();

    // Float transaction amount rejected
    await assertFails(
      setDoc(doc(aliceDb, `users/${ALICE_UID}/transactions/tx_float`), {
        ...validTransaction('tx_float'),
        amount: 50000.5,
      }),
    );

    // Zero or negative transaction amount rejected
    await assertFails(
      setDoc(doc(aliceDb, `users/${ALICE_UID}/transactions/tx_zero`), {
        ...validTransaction('tx_zero'),
        amount: 0,
      }),
    );

    // Float budget amount rejected
    await assertFails(
      setDoc(doc(aliceDb, `users/${ALICE_UID}/budgets/b_float`), {
        ...validBudget('b_float'),
        amount: 99.99,
      }),
    );

    // Float account balance rejected
    await assertFails(
      setDoc(doc(aliceDb, `users/${ALICE_UID}/accounts/acc_float`), {
        ...validAccount('acc_float'),
        balance: 100.75,
      }),
    );
  });

  it('rejects invalid enums, invalid transfer targets, extraneous fields, and immutable mutations', async () => {
    const aliceDb = testEnv.authenticatedContext(ALICE_UID).firestore();

    // Invalid transaction type
    await assertFails(
      setDoc(doc(aliceDb, `users/${ALICE_UID}/transactions/tx_bad_type`), {
        ...validTransaction('tx_bad_type'),
        type: 'crypto_swap',
      }),
    );

    // Invalid account type
    await assertFails(
      setDoc(doc(aliceDb, `users/${ALICE_UID}/accounts/acc_bad_type`), {
        ...validAccount('acc_bad_type'),
        type: 'stock',
      }),
    );

    // Invalid currency
    await assertFails(
      setDoc(doc(aliceDb, `users/${ALICE_UID}/accounts/acc_bad_cur`), {
        ...validAccount('acc_bad_cur'),
        currency: 'GBP',
      }),
    );

    // Transfer missing toAccountId or equal to source accountId
    await assertFails(
      setDoc(doc(aliceDb, `users/${ALICE_UID}/transactions/tx_bad_xfer_1`), {
        ...validTransaction('tx_bad_xfer_1'),
        type: 'transfer',
        toAccountId: null,
      }),
    );
    await assertFails(
      setDoc(doc(aliceDb, `users/${ALICE_UID}/transactions/tx_bad_xfer_2`), {
        ...validTransaction('tx_bad_xfer_2'),
        type: 'transfer',
        accountId: 'acc_cash',
        toAccountId: 'acc_cash',
      }),
    );

    // Extraneous / privilege escalation field rejected
    await assertFails(
      setDoc(doc(aliceDb, `users/${ALICE_UID}`), {
        ...validUserProfile(ALICE_UID),
        isAdmin: true,
      }),
    );

    // Oversized note (> 1000 chars) and non-string tag elements rejected
    await assertFails(
      setDoc(doc(aliceDb, `users/${ALICE_UID}/transactions/tx_big_note`), {
        ...validTransaction('tx_big_note'),
        note: 'x'.repeat(1001),
      }),
    );
    await assertFails(
      setDoc(doc(aliceDb, `users/${ALICE_UID}/transactions/tx_bad_tags`), {
        ...validTransaction('tx_bad_tags'),
        tags: ['ok', 123],
      }),
    );
    await assertFails(
      setDoc(doc(aliceDb, `users/${ALICE_UID}/transactions/tx_too_many_tags`), {
        ...validTransaction('tx_too_many_tags'),
        tags: Array.from({ length: 21 }, (_, i) => `tag_${i}`),
      }),
    );
    await assertFails(
      setDoc(doc(aliceDb, `users/${ALICE_UID}/transactions/tx_huge_tag`), {
        ...validTransaction('tx_huge_tag'),
        tags: ['x'.repeat(65)],
      }),
    );

    // Budget alertThreshold out of 1..100 range rejected
    await assertFails(
      setDoc(doc(aliceDb, `users/${ALICE_UID}/budgets/b_bad_thresh`), {
        ...validBudget('b_bad_thresh'),
        alertThreshold: 101,
      }),
    );

    // Immutable `createdAt` and `id` protected on update
    const accRef = doc(aliceDb, `users/${ALICE_UID}/accounts/acc_cash`);
    await assertSucceeds(setDoc(accRef, validAccount('acc_cash')));
    await assertFails(updateDoc(accRef, { createdAt: t2, updatedAt: t2 }));
    await assertFails(updateDoc(accRef, { id: 'tampered', updatedAt: t2 }));
    await assertFails(updateDoc(accRef, { name: deleteField(), updatedAt: t2 }));
  });

  it('allows partial updates: soft-delete, undo restore, archive toggle, and integer FieldValue.increment', async () => {
    const aliceDb = testEnv.authenticatedContext(ALICE_UID).firestore();

    const accRef = doc(aliceDb, `users/${ALICE_UID}/accounts/acc_cash`);
    const catRef = doc(aliceDb, `users/${ALICE_UID}/categories/default_food`);
    const txRef = doc(aliceDb, `users/${ALICE_UID}/transactions/tx_1`);
    const budgetRef = doc(aliceDb, `users/${ALICE_UID}/budgets/b_1`);

    await assertSucceeds(
      setDoc(accRef, { ...validAccount('acc_cash'), balance: 0 }),
    );
    await assertSucceeds(setDoc(catRef, validCategory('default_food')));
    await assertSucceeds(setDoc(txRef, validTransaction('tx_1')));
    await assertSucceeds(setDoc(budgetRef, validBudget('b_1')));

    // Archive toggle partial update
    await assertSucceeds(
      updateDoc(accRef, { archived: true, updatedAt: t1 }),
    );

    // Atomic WriteBatch with integer FieldValue.increment (including negative balance after expense)
    const batch = writeBatch(aliceDb);
    batch.update(accRef, {
      balance: increment(-50000),
      updatedAt: t1,
    });
    batch.update(txRef, {
      deletedAt: t1,
      updatedAt: t1,
    });
    await assertSucceeds(batch.commit());

    // Undo / restore soft-deleted transaction (`deletedAt: null`)
    await assertSucceeds(
      updateDoc(txRef, { deletedAt: null, updatedAt: t2 }),
    );

    // Soft-delete category, account, and budget
    await assertSucceeds(updateDoc(catRef, { deletedAt: t2, updatedAt: t2 }));
    await assertSucceeds(updateDoc(accRef, { deletedAt: t2, updatedAt: t2 }));
    await assertSucceeds(
      updateDoc(budgetRef, { deletedAt: t2, updatedAt: t2 }),
    );

    // Rejects float FieldValue.increment on account balance!
    await assertFails(
      updateDoc(accRef, { balance: increment(12.34), updatedAt: t2 }),
    );
  });

  it('enforces /users/{uid}/debts/{debtId} ownership, schema, repayment bounds, and immutability', async () => {
    const aliceDb = testEnv.authenticatedContext(ALICE_UID).firestore();
    const bobDb = testEnv.authenticatedContext(BOB_UID).firestore();

    const accRef = doc(aliceDb, `users/${ALICE_UID}/accounts/acc_cash`);
    const debtRef = doc(aliceDb, `users/${ALICE_UID}/debts/debt_1`);
    const borrowedRef = doc(aliceDb, `users/${ALICE_UID}/debts/debt_2`);

    await assertSucceeds(setDoc(accRef, validAccount('acc_cash')));

    // Owner create lent & borrowed debts (with optional nullable fields)
    await assertSucceeds(setDoc(debtRef, validDebt('debt_1')));
    await assertSucceeds(
      setDoc(borrowedRef, {
        ...validDebt('debt_2'),
        type: 'borrowed',
        phoneNumber: null,
        dueDate: null,
        accountId: null,
      }),
    );

    // Cross-user read/update/delete denied
    await assertFails(getDoc(doc(bobDb, `users/${ALICE_UID}/debts/debt_1`)));
    await assertFails(
      updateDoc(doc(bobDb, `users/${ALICE_UID}/debts/debt_1`), {
        remainingAmount: 0,
        updatedAt: t1,
      }),
    );
    await assertFails(deleteDoc(doc(bobDb, `users/${ALICE_UID}/debts/debt_1`)));

    // Repayment batch update (remainingAmount reduced, then paid in full = 0)
    const repayBatch = writeBatch(aliceDb);
    repayBatch.update(debtRef, { remainingAmount: 500000, updatedAt: t1 });
    repayBatch.update(accRef, { balance: increment(1000000), updatedAt: t1 });
    await assertSucceeds(repayBatch.commit());
    await assertSucceeds(
      updateDoc(debtRef, { remainingAmount: 0, updatedAt: t2 }),
    );

    // Rejects remainingAmount > amount, remainingAmount < 0, and floats
    await assertFails(
      updateDoc(debtRef, { remainingAmount: 1500001, updatedAt: t2 }),
    );
    await assertFails(
      updateDoc(debtRef, { remainingAmount: -1, updatedAt: t2 }),
    );
    await assertFails(
      setDoc(doc(aliceDb, `users/${ALICE_UID}/debts/debt_float`), {
        ...validDebt('debt_float'),
        amount: 100.5,
        remainingAmount: 50,
      }),
    );

    // Rejects invalid debt type, oversized phoneNumber (> 20 chars), and extraneous keys
    await assertFails(
      setDoc(doc(aliceDb, `users/${ALICE_UID}/debts/debt_bad_type`), {
        ...validDebt('debt_bad_type'),
        type: 'mortgage',
      }),
    );
    await assertFails(
      setDoc(doc(aliceDb, `users/${ALICE_UID}/debts/debt_bad_phone`), {
        ...validDebt('debt_bad_phone'),
        phoneNumber: '012345678901234567890',
      }),
    );
    await assertFails(
      setDoc(doc(aliceDb, `users/${ALICE_UID}/debts/debt_extra`), {
        ...validDebt('debt_extra'),
        extra: true,
      }),
    );

    // Protects immutable `id` and `createdAt` on update
    await assertFails(updateDoc(debtRef, { id: 'hijacked', updatedAt: t2 }));
    await assertFails(updateDoc(debtRef, { createdAt: t2, updatedAt: t2 }));

    // Allows soft-delete and hard-delete for owner
    await assertSucceeds(updateDoc(debtRef, { deletedAt: t2, updatedAt: t2 }));
    await assertSucceeds(deleteDoc(debtRef));
    await assertSucceeds(deleteDoc(borrowedRef));
  });

  it('enforces /users/{uid}/recurring/{recurringId} ownership, schema, frequency/bounds, and immutability', async () => {
    const aliceDb = testEnv.authenticatedContext(ALICE_UID).firestore();
    const bobDb = testEnv.authenticatedContext(BOB_UID).firestore();

    const recRef = doc(aliceDb, `users/${ALICE_UID}/recurring/rec_1`);
    const recWeeklyRef = doc(aliceDb, `users/${ALICE_UID}/recurring/rec_2`);

    // Owner create monthly expense recurring with dayOfMonth
    await assertSucceeds(setDoc(recRef, validRecurring('rec_1')));

    // Owner create weekly income recurring without dayOfMonth (null)
    await assertSucceeds(
      setDoc(recWeeklyRef, {
        ...validRecurring('rec_2'),
        type: 'income',
        frequency: 'weekly',
        dayOfMonth: null,
      }),
    );

    // Cross-user read/update/delete denied
    await assertFails(getDoc(doc(bobDb, `users/${ALICE_UID}/recurring/rec_1`)));
    await assertFails(
      updateDoc(doc(bobDb, `users/${ALICE_UID}/recurring/rec_1`), {
        isActive: false,
        updatedAt: t1,
      }),
    );
    await assertFails(
      deleteDoc(doc(bobDb, `users/${ALICE_UID}/recurring/rec_1`)),
    );

    // Rejects non-positive amount and float amounts
    await assertFails(
      setDoc(doc(aliceDb, `users/${ALICE_UID}/recurring/rec_bad_amt_0`), {
        ...validRecurring('rec_bad_amt_0'),
        amount: 0,
      }),
    );
    await assertFails(
      setDoc(doc(aliceDb, `users/${ALICE_UID}/recurring/rec_bad_amt_neg`), {
        ...validRecurring('rec_bad_amt_neg'),
        amount: -5000,
      }),
    );
    await assertFails(
      setDoc(doc(aliceDb, `users/${ALICE_UID}/recurring/rec_bad_amt_float`), {
        ...validRecurring('rec_bad_amt_float'),
        amount: 50000.5,
      }),
    );

    // Rejects invalid frequency and invalid recurring type (transfer IS allowed)
    await assertFails(
      setDoc(doc(aliceDb, `users/${ALICE_UID}/recurring/rec_bad_freq`), {
        ...validRecurring('rec_bad_freq'),
        frequency: 'hourly',
      }),
    );
    await assertFails(
      setDoc(doc(aliceDb, `users/${ALICE_UID}/recurring/rec_bad_type`), {
        ...validRecurring('rec_bad_type'),
        type: 'invalid_type',
      }),
    );

    // Owner creates recurring transfer with full Flutter client schema (interval, startDate, toAccountId, autoExecute, isPaused)
    const recTransferRef = doc(aliceDb, `users/${ALICE_UID}/recurring/rec_transfer`);
    await assertSucceeds(
      setDoc(recTransferRef, {
        id: 'rec_transfer',
        title: 'Chuyển tiền tiết kiệm định kỳ',
        amount: 2000000,
        currency: 'VND',
        type: 'transfer',
        interval: 'monthly',
        frequency: 'monthly',
        intervalCount: 1,
        startDate: t0,
        nextDueDate: t1,
        lastExecutedDate: null,
        accountId: 'acc_bank',
        toAccountId: 'acc_cash',
        categoryId: 'default_other',
        autoExecute: true,
        isPaused: false,
        isActive: true,
        note: 'Tự động trích tiền lương',
        createdAt: t0,
        updatedAt: t0,
      }),
    );

    // Rejects dayOfMonth out of bounds (0, 32, float)
    await assertFails(
      setDoc(doc(aliceDb, `users/${ALICE_UID}/recurring/rec_bad_dom_0`), {
        ...validRecurring('rec_bad_dom_0'),
        dayOfMonth: 0,
      }),
    );
    await assertFails(
      setDoc(doc(aliceDb, `users/${ALICE_UID}/recurring/rec_bad_dom_32`), {
        ...validRecurring('rec_bad_dom_32'),
        dayOfMonth: 32,
      }),
    );
    await assertFails(
      setDoc(doc(aliceDb, `users/${ALICE_UID}/recurring/rec_bad_dom_float`), {
        ...validRecurring('rec_bad_dom_float'),
        dayOfMonth: 15.5,
      }),
    );

    // Rejects oversized note (> 1000 chars) and extraneous fields
    await assertFails(
      setDoc(doc(aliceDb, `users/${ALICE_UID}/recurring/rec_bad_note`), {
        ...validRecurring('rec_bad_note'),
        note: 'x'.repeat(1001),
      }),
    );
    await assertFails(
      setDoc(doc(aliceDb, `users/${ALICE_UID}/recurring/rec_extra`), {
        ...validRecurring('rec_extra'),
        extraKey: true,
      }),
    );

    // Partial update allowed for owner
    await assertSucceeds(
      updateDoc(recRef, {
        isActive: false,
        lastExecutedDate: t1,
        updatedAt: t1,
      }),
    );

    // Protects immutable `id` and `createdAt` on update
    await assertFails(updateDoc(recRef, { id: 'tampered', updatedAt: t2 }));
    await assertFails(updateDoc(recRef, { createdAt: t2, updatedAt: t2 }));

    // Soft-delete and hard-delete allowed for owner
    await assertSucceeds(updateDoc(recRef, { deletedAt: t2, updatedAt: t2 }));
    await assertSucceeds(deleteDoc(recRef));
    await assertSucceeds(deleteDoc(recWeeklyRef));
    await assertSucceeds(deleteDoc(recTransferRef));
  });

  it('enforces /users/{uid}/savings_goals/{goalId} ownership, schema, non-negative amounts, and immutability', async () => {
    const aliceDb = testEnv.authenticatedContext(ALICE_UID).firestore();
    const bobDb = testEnv.authenticatedContext(BOB_UID).firestore();

    const goalRef = doc(aliceDb, `users/${ALICE_UID}/savings_goals/goal_1`);
    const goal2Ref = doc(aliceDb, `users/${ALICE_UID}/savings_goals/goal_2`);

    // Owner create valid savings goal
    await assertSucceeds(setDoc(goalRef, validSavingsGoal('goal_1')));

    // Owner create goal with currentAmount 0, null deadline and accountId
    await assertSucceeds(
      setDoc(goal2Ref, {
        ...validSavingsGoal('goal_2'),
        currentAmount: 0,
        deadline: null,
        accountId: null,
      }),
    );

    // Cross-user read/update/delete denied
    await assertFails(
      getDoc(doc(bobDb, `users/${ALICE_UID}/savings_goals/goal_1`)),
    );
    await assertFails(
      updateDoc(doc(bobDb, `users/${ALICE_UID}/savings_goals/goal_1`), {
        currentAmount: 0,
        updatedAt: t1,
      }),
    );
    await assertFails(
      deleteDoc(doc(bobDb, `users/${ALICE_UID}/savings_goals/goal_1`)),
    );

    // Rejects non-positive targetAmount and floats
    await assertFails(
      setDoc(doc(aliceDb, `users/${ALICE_UID}/savings_goals/g_bad_target_0`), {
        ...validSavingsGoal('g_bad_target_0'),
        targetAmount: 0,
      }),
    );
    await assertFails(
      setDoc(doc(aliceDb, `users/${ALICE_UID}/savings_goals/g_bad_target_fl`), {
        ...validSavingsGoal('g_bad_target_fl'),
        targetAmount: 1000.5,
      }),
    );

    // Rejects negative currentAmount and float currentAmount
    await assertFails(
      setDoc(doc(aliceDb, `users/${ALICE_UID}/savings_goals/g_bad_cur_neg`), {
        ...validSavingsGoal('g_bad_cur_neg'),
        currentAmount: -100,
      }),
    );
    await assertFails(
      setDoc(doc(aliceDb, `users/${ALICE_UID}/savings_goals/g_bad_cur_fl`), {
        ...validSavingsGoal('g_bad_cur_fl'),
        currentAmount: 50.75,
      }),
    );

    // Rejects invalid currency and invalid color int
    await assertFails(
      setDoc(doc(aliceDb, `users/${ALICE_UID}/savings_goals/g_bad_cur`), {
        ...validSavingsGoal('g_bad_cur'),
        currency: 'INVALID',
      }),
    );
    await assertFails(
      setDoc(doc(aliceDb, `users/${ALICE_UID}/savings_goals/g_bad_col`), {
        ...validSavingsGoal('g_bad_col'),
        color: 'red',
      }),
    );

    // Rejects oversized note (> 1000) and oversized name (> 100)
    await assertFails(
      setDoc(doc(aliceDb, `users/${ALICE_UID}/savings_goals/g_big_name`), {
        ...validSavingsGoal('g_big_name'),
        name: 'x'.repeat(101),
      }),
    );
    await assertFails(
      setDoc(doc(aliceDb, `users/${ALICE_UID}/savings_goals/g_big_note`), {
        ...validSavingsGoal('g_big_note'),
        note: 'x'.repeat(1001),
      }),
    );

    // Owner creates savings goal with Flutter client payload (title, linkedAccountId, isCompleted, without id)
    const goalFlutterRef = doc(aliceDb, `users/${ALICE_UID}/savings_goals/goal_flutter`);
    await assertSucceeds(
      setDoc(goalFlutterRef, {
        title: 'Quỹ du lịch Nhật Bản',
        name: 'Quỹ du lịch Nhật Bản',
        targetAmount: 50000000,
        currentAmount: 15000000,
        currency: 'VND',
        deadline: t2,
        icon: 'flight',
        color: 0xff0d7c66,
        isCompleted: false,
        linkedAccountId: 'acc_bank',
        accountId: 'acc_bank',
        note: 'Tiết kiệm đi Tokyo',
        createdAt: t0,
        updatedAt: t0,
      }),
    );

    // Goal with only title (omitting name and id) succeeds
    const goalTitleOnlyRef = doc(aliceDb, `users/${ALICE_UID}/savings_goals/goal_title_only`);
    await assertSucceeds(
      setDoc(goalTitleOnlyRef, {
        title: 'Mua laptop mới',
        targetAmount: 30000000,
        currentAmount: 5000000,
        currency: 'VND',
        icon: 'laptop',
        color: 0xff0d7c66,
        createdAt: t0,
        updatedAt: t0,
      }),
    );

    // Rejects goal with neither title nor name
    await assertFails(
      setDoc(doc(aliceDb, `users/${ALICE_UID}/savings_goals/goal_no_title`), {
        targetAmount: 10000000,
        currentAmount: 0,
        currency: 'VND',
        icon: 'star',
        color: 0xff0d7c66,
        createdAt: t0,
        updatedAt: t0,
      }),
    );

    // Rejects invalid isCompleted type (must be bool)
    await assertFails(
      setDoc(doc(aliceDb, `users/${ALICE_UID}/savings_goals/goal_bad_is_completed`), {
        ...validSavingsGoal('goal_bad_is_completed'),
        isCompleted: 'yes',
      }),
    );

    // Owner partial update (deposit progress)
    await assertSucceeds(
      updateDoc(goalRef, {
        currentAmount: increment(5000000),
        updatedAt: t1,
      }),
    );

    // Protects immutable `id` and `createdAt` on update
    await assertFails(updateDoc(goalRef, { id: 'tampered', updatedAt: t2 }));
    await assertFails(updateDoc(goalRef, { createdAt: t2, updatedAt: t2 }));

    // Soft-delete and hard-delete allowed for owner
    await assertSucceeds(updateDoc(goalRef, { deletedAt: t2, updatedAt: t2 }));
    await assertSucceeds(deleteDoc(goalRef));
    await assertSucceeds(deleteDoc(goal2Ref));
    await assertSucceeds(deleteDoc(goalFlutterRef));
    await assertSucceeds(deleteDoc(goalTitleOnlyRef));
  });

  it('enforces /users/{uid}/ledgers/{ledgerId} ownership, schema, sharedMemberEmails bounds, and immutability', async () => {
    const aliceDb = testEnv.authenticatedContext(ALICE_UID).firestore();
    const bobDb = testEnv.authenticatedContext(BOB_UID).firestore();

    const ledgerRef = doc(aliceDb, `users/${ALICE_UID}/ledgers/ledger_1`);
    const ledgerEmptyRef = doc(aliceDb, `users/${ALICE_UID}/ledgers/ledger_2`);
    const ledgerDtoRef = doc(aliceDb, `users/${ALICE_UID}/ledgers/ledger_dto`);
    const ledgerNullsRef = doc(aliceDb, `users/${ALICE_UID}/ledgers/ledger_nulls`);

    // 1. Owner create valid ledger with all fields (including description & sharedMemberEmails)
    await assertSucceeds(setDoc(ledgerRef, validLedger('ledger_1')));

    // 2. Owner create valid ledger strictly matching LedgerBookDto.toJson()
    // (omits description, sharedMemberEmails, and deletedAt)
    const dtoData = {
      id: 'ledger_dto',
      name: 'Sổ Cá Nhân',
      type: 'personal',
      icon: 'person',
      color: 0x00a86b,
      currency: 'VND',
      isDefault: true,
      createdAt: t0,
      updatedAt: t0,
    };
    await assertSucceeds(setDoc(ledgerDtoRef, dtoData));

    // 3. Owner create valid ledger with description & sharedMemberEmails explicitly set to null
    await assertSucceeds(
      setDoc(ledgerNullsRef, {
        ...validLedger('ledger_nulls'),
        type: 'business',
        currency: 'USD',
        description: null,
        sharedMemberEmails: null,
      }),
    );

    // 4. Owner create valid ledger with empty sharedMemberEmails list
    await assertSucceeds(
      setDoc(ledgerEmptyRef, {
        ...validLedger('ledger_2'),
        type: 'custom',
        sharedMemberEmails: [],
        description: '',
      }),
    );

    // 5. Cross-user read/update/delete denied
    await assertFails(
      getDoc(doc(bobDb, `users/${ALICE_UID}/ledgers/ledger_1`)),
    );
    await assertFails(
      updateDoc(doc(bobDb, `users/${ALICE_UID}/ledgers/ledger_1`), {
        name: 'Hacked Ledger',
        updatedAt: t1,
      }),
    );
    await assertFails(
      deleteDoc(doc(bobDb, `users/${ALICE_UID}/ledgers/ledger_1`)),
    );

    // 6. Rejects invalid ledger type
    await assertFails(
      setDoc(doc(aliceDb, `users/${ALICE_UID}/ledgers/l_bad_type`), {
        ...validLedger('l_bad_type'),
        type: 'crypto_vault',
      }),
    );

    // 7. Rejects invalid currency
    await assertFails(
      setDoc(doc(aliceDb, `users/${ALICE_UID}/ledgers/l_bad_cur`), {
        ...validLedger('l_bad_cur'),
        currency: 'GBP',
      }),
    );

    // 8. Rejects missing required fields (e.g. type, currency, isDefault)
    const { type: _t, ...missingType } = validLedger('l_miss_type');
    await assertFails(
      setDoc(doc(aliceDb, `users/${ALICE_UID}/ledgers/l_miss_type`), missingType),
    );
    const { currency: _c, ...missingCurrency } = validLedger('l_miss_cur');
    await assertFails(
      setDoc(doc(aliceDb, `users/${ALICE_UID}/ledgers/l_miss_cur`), missingCurrency),
    );

    // 9. Rejects oversized description (> 500 chars)
    await assertFails(
      setDoc(doc(aliceDb, `users/${ALICE_UID}/ledgers/l_big_desc`), {
        ...validLedger('l_big_desc'),
        description: 'x'.repeat(501),
      }),
    );

    // 10. Rejects > 20 shared member emails
    await assertFails(
      setDoc(doc(aliceDb, `users/${ALICE_UID}/ledgers/l_too_many_emails`), {
        ...validLedger('l_too_many_emails'),
        sharedMemberEmails: Array.from(
          { length: 21 },
          (_, i) => `member_${i}@example.com`,
        ),
      }),
    );

    // 11. Rejects oversized email (> 320 chars) and non-string elements
    await assertFails(
      setDoc(doc(aliceDb, `users/${ALICE_UID}/ledgers/l_big_email`), {
        ...validLedger('l_big_email'),
        sharedMemberEmails: [`${'a'.repeat(310)}@example.com`],
      }),
    );
    await assertFails(
      setDoc(doc(aliceDb, `users/${ALICE_UID}/ledgers/l_non_str_email`), {
        ...validLedger('l_non_str_email'),
        sharedMemberEmails: ['alice@example.com', 12345],
      }),
    );

    // 12. Rejects invalid color int and non-boolean isDefault
    await assertFails(
      setDoc(doc(aliceDb, `users/${ALICE_UID}/ledgers/l_bad_color`), {
        ...validLedger('l_bad_color'),
        color: 'blue',
      }),
    );
    await assertFails(
      setDoc(doc(aliceDb, `users/${ALICE_UID}/ledgers/l_bad_def`), {
        ...validLedger('l_bad_def'),
        isDefault: 'true',
      }),
    );

    // 13. Owner partial update (toggle default status & modify name)
    await assertSucceeds(
      updateDoc(ledgerRef, {
        isDefault: true,
        updatedAt: t1,
      }),
    );
    await assertSucceeds(
      updateDoc(ledgerDtoRef, {
        name: 'Sổ Chi Tiêu Chính',
        description: 'Đã cập nhật mô tả',
        updatedAt: t1,
      }),
    );

    // 14. Protects immutable `id` and `createdAt` on update
    await assertFails(updateDoc(ledgerRef, { id: 'tampered', updatedAt: t2 }));
    await assertFails(updateDoc(ledgerRef, { createdAt: t2, updatedAt: t2 }));

    // 15. Soft-delete and hard-delete allowed for owner
    await assertSucceeds(updateDoc(ledgerRef, { deletedAt: t2, updatedAt: t2 }));
    await assertSucceeds(deleteDoc(ledgerRef));
    await assertSucceeds(deleteDoc(ledgerEmptyRef));
    await assertSucceeds(deleteDoc(ledgerDtoRef));
    await assertSucceeds(deleteDoc(ledgerNullsRef));
  });

  it('validates ledgerId field support across budgets, accounts, transactions, debts, recurring, savings goals, and categories', async () => {
    const aliceDb = testEnv.authenticatedContext(ALICE_UID).firestore();

    // 1. Budget with ledgerId ('default_personal' and custom ledgerId)
    const budget1Ref = doc(aliceDb, `users/${ALICE_UID}/budgets/b_ledger_1`);
    const budget2Ref = doc(aliceDb, `users/${ALICE_UID}/budgets/b_ledger_2`);
    await assertSucceeds(
      setDoc(budget1Ref, {
        ...validBudget('b_ledger_1'),
        ledgerId: 'default_personal',
      }),
    );
    await assertSucceeds(
      setDoc(budget2Ref, {
        ...validBudget('b_ledger_2'),
        ledgerId: 'ledger_custom_biz',
      }),
    );

    // 2. Account with ledgerId
    const accRef = doc(aliceDb, `users/${ALICE_UID}/accounts/acc_ledger`);
    await assertSucceeds(
      setDoc(accRef, {
        ...validAccount('acc_ledger'),
        ledgerId: 'default_personal',
      }),
    );

    // 3. Transaction with ledgerId
    const txRef = doc(aliceDb, `users/${ALICE_UID}/transactions/tx_ledger`);
    await assertSucceeds(
      setDoc(txRef, {
        ...validTransaction('tx_ledger'),
        ledgerId: 'default_personal',
      }),
    );

    // 4. Debt, Recurring, Savings Goal, Category with ledgerId
    const debtRef = doc(aliceDb, `users/${ALICE_UID}/debts/debt_ledger`);
    const recRef = doc(aliceDb, `users/${ALICE_UID}/recurring/rec_ledger`);
    const goalRef = doc(aliceDb, `users/${ALICE_UID}/savings_goals/goal_ledger`);
    const catRef = doc(aliceDb, `users/${ALICE_UID}/categories/cat_ledger`);

    await assertSucceeds(
      setDoc(debtRef, {
        ...validDebt('debt_ledger'),
        ledgerId: 'default_personal',
      }),
    );
    await assertSucceeds(
      setDoc(recRef, {
        ...validRecurring('rec_ledger'),
        ledgerId: 'default_personal',
      }),
    );
    await assertSucceeds(
      setDoc(goalRef, {
        ...validSavingsGoal('goal_ledger'),
        ledgerId: 'default_personal',
      }),
    );
    await assertSucceeds(
      setDoc(catRef, {
        ...validCategory('cat_ledger'),
        ledgerId: 'default_personal',
      }),
    );

    // 5. Rejects empty string ledgerId ("")
    await assertFails(
      setDoc(doc(aliceDb, `users/${ALICE_UID}/budgets/b_empty_ledger`), {
        ...validBudget('b_empty_ledger'),
        ledgerId: '',
      }),
    );

    // 6. Rejects oversized ledgerId (> 128 chars)
    await assertFails(
      setDoc(doc(aliceDb, `users/${ALICE_UID}/budgets/b_huge_ledger`), {
        ...validBudget('b_huge_ledger'),
        ledgerId: 'x'.repeat(129),
      }),
    );
    await assertFails(
      setDoc(doc(aliceDb, `users/${ALICE_UID}/accounts/acc_huge_ledger`), {
        ...validAccount('acc_huge_ledger'),
        ledgerId: 'x'.repeat(129),
      }),
    );
    await assertFails(
      setDoc(doc(aliceDb, `users/${ALICE_UID}/transactions/tx_huge_ledger`), {
        ...validTransaction('tx_huge_ledger'),
        ledgerId: 'x'.repeat(129),
      }),
    );

    // 7. Rejects non-string ledgerId (e.g. number or bool)
    await assertFails(
      setDoc(doc(aliceDb, `users/${ALICE_UID}/budgets/b_bad_ledger_type`), {
        ...validBudget('b_bad_ledger_type'),
        ledgerId: 12345,
      }),
    );
    await assertFails(
      setDoc(doc(aliceDb, `users/${ALICE_UID}/accounts/acc_bad_ledger_type`), {
        ...validAccount('acc_bad_ledger_type'),
        ledgerId: true,
      }),
    );

    // 8. Update with ledgerId succeeds
    await assertSucceeds(
      updateDoc(budget1Ref, {
        ledgerId: 'ledger_updated_personal',
        updatedAt: t1,
      }),
    );
  });
});
