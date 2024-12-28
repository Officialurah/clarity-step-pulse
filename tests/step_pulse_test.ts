import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Ensures user can register with daily goal",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet1 = accounts.get('wallet_1')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('step_pulse', 'register', [
        types.uint(10000)  // 10k steps daily goal
      ], wallet1.address)
    ]);
    
    block.receipts[0].result.expectOk();
    
    // Verify registration
    let userData = chain.callReadOnlyFn(
      'step_pulse',
      'get-user-data',
      [types.principal(wallet1.address)],
      wallet1.address
    );
    
    assertEquals(userData.result.expectSome().daily-goal, types.uint(10000));
  }
});

Clarinet.test({
  name: "Tests complete reward cycle - log steps and claim reward",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet1 = accounts.get('wallet_1')!;
    const day = 1;
    
    let block = chain.mineBlock([
      // Register user
      Tx.contractCall('step_pulse', 'register', [
        types.uint(10000)
      ], wallet1.address),
      
      // Log steps
      Tx.contractCall('step_pulse', 'log-steps', [
        types.uint(11000),  // More than daily goal
        types.uint(day)
      ], wallet1.address),
      
      // Claim reward
      Tx.contractCall('step_pulse', 'claim-reward', [
        types.uint(day)
      ], wallet1.address)
    ]);
    
    block.receipts.forEach(receipt => {
      receipt.result.expectOk();
    });
    
    // Verify balance
    let balanceCheck = chain.callReadOnlyFn(
      'step_pulse',
      'get-balance',
      [types.principal(wallet1.address)],
      wallet1.address
    );
    
    assertEquals(balanceCheck.result.expectOk(), types.uint(10)); // Should have received 10 tokens
  }
});