//// This module contains code that assists with payout logic. Payout
//// functions are designed to return a boolean value instead of an error.
////

use cardano/address.{Address}
use cardano/addresses
use cardano/assets.{Value}
use cardano/transaction.{Output, Transaction}
use cardano/value
// for testing only
use tests/fake_tx

/// Find the first occurrence of an exact output that matches a specific
/// address and assets. If nothing is found then return False.
///
/// ```aiken
/// payout.exact(wallet_addr, validating_value, tx.outputs)
/// ```
pub fn exact(
  payout_address: Address,
  payout_value: Value,
  outputs: List<Output>,
) -> Bool {
  when outputs is {
    [output, ..rest] ->
      // exact address and value
      if and {
        output.address == payout_address,
        output.value == payout_value,
      } {
        True
      } else {
        exact(payout_address, payout_value, rest)
      }
    // nothing was found
    [] -> False
  }
}

test find_exact_payout() {
  let tx: Transaction = fake_tx.test_tx()
  let addr: Address = addresses.create_address(#"face", #"")
  let val: Value = assets.from_lovelace(40)
  exact(addr, val, tx.outputs) == True
}

test missing_exact_payout() {
  let tx: Transaction = fake_tx.test_tx()
  let addr: Address = addresses.create_address(#"acab", #"")
  let val: Value = assets.from_lovelace(40)
  exact(addr, val, tx.outputs) == False
}

/// Find the first occurrence of an output that contains at least some specific
/// value at some address. If nothing is found then return False. This function
/// does not search for an exact UTxO match.
///
/// ```aiken
/// payout.at_least(wallet_addr, just_token_value, tx.outputs)
/// ```
pub fn at_least(
  payout_address: Address,
  payout_value: Value,
  outputs: List<Output>,
) -> Bool {
  when outputs is {
    [output, ..rest] ->
      if and {
        output.address == payout_address,
        value.contains(output.value, payout_value),
      } {
        True
      } else {
        at_least(payout_address, payout_value, rest)
      }
    // nothing was found
    [] -> False
  }
}

test at_least_payout() {
  let tx: Transaction = fake_tx.test_tx()
  let addr: Address = addresses.create_address(#"acab", #"")
  let val: Value = assets.from_asset(#"acab", #"beef", 40)
  at_least(addr, val, tx.outputs) == True
}

test find_just_enough_token_payout() {
  let tx: Transaction = fake_tx.test_tx()
  let addr: Address = addresses.create_address(#"acab", #"")
  let val: Value = assets.from_asset(#"acab", #"beef", 20)
  at_least(addr, val, tx.outputs) == True
}

test missing_token_payout() {
  let tx: Transaction = fake_tx.test_tx()
  let addr: Address = addresses.create_address(#"acab", #"")
  let val: Value = assets.from_asset(#"acab", #"beef", 60)
  at_least(addr, val, tx.outputs) == False
}

test negative_token_payout() {
  let tx: Transaction = fake_tx.test_tx()
  let addr: Address = addresses.create_address(#"acab", #"")
  let val: Value = assets.from_asset(#"acab", #"beef", -20)
  at_least(addr, val, tx.outputs) == True
}
