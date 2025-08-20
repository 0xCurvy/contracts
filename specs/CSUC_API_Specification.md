# CSUC Interaction API Specification

## Curvy User's CSA

```ts
class CSUC_CSA {
    private runtime: string;
    private rpcUrl: string;
    private account: CSUC_Types.Account;
    private csuc: CSUC_Types.Contract;

    /**
     * Creates a new CSUC_CSA instance.
     * @param {string} runtime - Supported runtime (e.g., 'EVM', 'Starknet').
     * @param {string} rpcUrl - RPC endpoint URL.
     * @param {string} privateKey - Private key for the account.
     */
    constructor(
        runtime: CSUC_Enum.SupportedRuntimes,
        rpcUrl: string,
        privateKey: string
    ) {
        // 1. sets the `this.runtime/rpcUrl/...` class members
        // 2. instantiates necessary account based on `runtime`
        // Example: if(runtime === 'EVM') {
        //      this.csuc = new Contract(env.EVM.CSUC_ABI, ...)
    }

    /**
     * Transfers tokens to a destination (within CSUC contract).
     * @param {CSUC_Types.Destination} to - CSA destination.
     * @param {CSUC_Types.Address} token - Token address.
     * @param {CSUC_Types.Amount} amount - Amount to transfer.
     * @returns {Promise<CSUC_Types.Action | Error>} Action object representing the transfer.
     */
    function transfer(to: CSUC_Types.Destination, token: CSUC_Types.Address, amount: CSUC_Types.Amount) : Promise<CSUC_Types.ActionStatus | Error > {
        // 1. creates `actionIntent: CSUC_Types.ActionIntent`
        // 2. calls `this.estimateAction(action)`
        // 3. decides on the `fee` option - fast / slow / medium
        // 4. creates `action: CSUC_Types.Action`
        // 5. calls: `this.submitAction(action)`
    }

    /**
     * Withdraws tokens to a desired recipient.
     * @param {CSUC_Types.Destination} to - Runtime Address.
     * @param {CSUC_Types.Address} token - Token address.
     * @param {CSUC_Types.Amount} amount - Amount to transfer.
     * @returns {Promise<CSUC_Types.Action | Error>} Action object representing the transfer.
     */
    function withdraw(to: CSUC_Types.Destination, token: CSUC_Types.Address, amount: CSUC_Types.Amount) : Promise<CSUC_Types.ActionStatus | Error> {
        // ...similar as with `this.transfer(...)`...
    }

    /**
     * Estimates the costs that the CSUC_CSA will have to pay.
     * @param {CSUC_Types.ActionIntent} actionIntent - Intended Action.
     * @returns {Promise<CSUC_Types.EstimatedActionCost>} Action object representing the transfer.
     */
    function estimateAction(actionIntent: CSUC_Types.ActionIntent) : Promise<CSUC_Types.EstimatedActionCost | Error> {
        // 1. calls `GET: /estimate-action-cost` with `action` as param.
    }

    /**
     * Submits the Action (with fees, and signature set) to be included on-chain.
     * @param {CSUC_Types.Action} action - Valid Action object.
     * @returns {Promise<CSUC_Types.ActionStatus>} Status of the newly submitted Action.
     */
    function submitAction(action: CSUC_Types.Action) : Promise<CSUC_Types.ActionStatus | Error> {
        // 1. calls `POST: /submit-action` with `action` as param.
    }
}
```

## Curvy Operator

```ts
class CSUC_Operator {
    private runtime: string;
    private rpcUrl: string;
    private account: CSUC_Types.Account;
    private csuc: CSUC_Types.Contract;

    /**
     * Creates a new CSUC_Operator instance.
     * @param {string} runtime - Supported runtime (e.g., 'EVM', 'Starknet').
     * @param {string} rpcUrl - RPC endpoint URL.
     * @param {string} privateKey - Private key for the account.
     */
    constructor(
        runtime: CSUC_Enum.SupportedRuntimes,
        rpcUrl: string,
        privateKey: string
    ) {
        // 1. sets the `this.runtime/rpcUrl/...` class members
        // 2. instantiates necessary account & contract objects based on `runtime`
        // Example: if(runtime === 'EVM') {
        //      this.csuc = new Contract(env.EVM.CSUC_ABI, ...)
    }

    /**
     * Executes a list of valid User's actions on-chain.
     * @param {[]CSUC_Types.Action} actions - Signed User Actions.
     * @returns {Promise<CSUC_Types.Transaction | Error>} On-chain Transaction.
     */
    function operatorExecute(actions: []CSUC_Types.Action) : Promise<CSUC_Types.Transaction | Error> {
        // Based on `this.runtime`:
        //  1. simulates the transaction
        //  2. if it won't revert, submits it on-chain

        // Example: if(runtime === 'EVM') {
        //      Simulate: https://www.alchemy.com/docs/how-to-simulate-a-transaction-on-ethereum
        //      return await this.csuc.operatorExecute(actions)
    }
}
```

## Curvy Admin / Owner

```ts
class CSUC_Admin {
    private runtime: string;
    private rpcUrl: string;
    private account: CSUC_Types.Account;
    private csuc: CSUC_Types.Contract;

    /**
     * Creates a new CSUC_Admin instance.
     * @param {string} runtime - Supported runtime (e.g., 'EVM', 'Starknet').
     * @param {string} rpcUrl - RPC endpoint URL.
     * @param {string} privateKey - Private key for the account.
     */
    constructor(
        runtime: CSUC_Enum.SupportedRuntimes,
        rpcUrl: string,
        privateKey: string
    ) {
        // Sets up all needed `this.<member> = ...` variables
    }

    /**
     * Adds new or updates existing Actions inside CSUC contract.
     * @param {CSUC_Types.ConfigUpdate} update - Updates to the CSUC on-chain configuration.
     * @returns {Promise<CSUC_Types.Transaction | Error>} On-chain Transaction.
     */
    function updateConfig(update: CSUC_Types.ConfigUpdate) : Promise<CSUC_Types.Transaction | Error> {
        // Based on `this.runtime`:
        //  1. simulates the transaction
        //  2. if it won't revert, submits it on-chain
    }
}
```

## Structures / Types

```ts
type CSUC_Types.ActionWithoutSignature = CSUC_Types.Action;

type CSUC_Types.Transaction = Ethers.Transaction | Starknet.Transaction | ...other runtimes... ;

type CSUC_Types.Destination = Ethers.Address | Starknet.Felt252 | ...other runtimes... ;

type CSUC_Types.Amount = Ethers.Uint256 | Starknet.Felt252 | ...other runtimes... ;

type CSUC_Types.Account = Ethers.Account | Starknet.Account | ...other runtimes... ;

type CSUC_Types.Contract = Ethers.Contract | Starknet.Contract | ...other runtimes... ;
```
