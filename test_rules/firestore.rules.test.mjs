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
});
