// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/**
 * @title Multi-Signature Wallet
 * @dev A professional-grade wallet requiring M-of-N signatures to move funds.
 * Part of the Level 4: Infrastructure
 */
contract MultiSig {
    // --- Events ---
    event Deposit(address indexed sender, uint256 amount);
    event SubmitTransaction(address indexed owner, uint256 indexed txIndex);
    event ConfirmTransaction(address indexed owner, uint256 indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint256 indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint256 indexed txIndex);

    // --- State Variables ---
    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public numConfirmationsRequired;

    struct Transaction {
        address to;
        uint256 value;
        bool executed;
        uint256 numConfirmations;
    }

    Transaction[] public transactions;
    // txIndex => owner => confirmed?
    mapping(uint256 => mapping(address => bool)) public isConfirmed;

    // --- Custom Errors (Gas Optimized) ---
    error NotOwner();
    error TxDoesNotExist();
    error TxAlreadyExecuted();
    error TxAlreadyConfirmed();
    error TxNotConfirmed();
    error CannotExecuteTx();
    error TransferFailed();
    error InvalidOwnerCount();
    error InvalidThreshold();
    error InvalidOwner();
    error OwnerNotUnique();

    // --- Modifiers ---
    modifier onlyOwner() {
        if (!isOwner[msg.sender]) revert NotOwner();
        _;
    }

    modifier txExists(uint256 _txIndex) {
        if (_txIndex >= transactions.length) revert TxDoesNotExist();
        _;
    }

    modifier notExecuted(uint256 _txIndex) {
        if (transactions[_txIndex].executed) revert TxAlreadyExecuted();
        _;
    }

    modifier notConfirmed(uint256 _txIndex) {
        if (isConfirmed[_txIndex][msg.sender]) revert TxAlreadyConfirmed();
        _;
    }

    constructor(address[] memory _owners, uint256 _required) {
        if (_owners.length == 0) revert InvalidOwnerCount();
        if (_required == 0 || _required > _owners.length) {
            revert InvalidThreshold();
        }

        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            if (owner == address(0)) revert InvalidOwner();
            if (isOwner[owner]) revert OwnerNotUnique();

            isOwner[owner] = true;
            owners.push(owner);
        }

        numConfirmationsRequired = _required;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    // --- Core Functions ---

    function submitTransaction(address _to, uint256 _value) external onlyOwner {
        uint256 txIndex = transactions.length;

        transactions.push(Transaction({to: _to, value: _value, executed: false, numConfirmations: 0}));

        emit SubmitTransaction(msg.sender, txIndex);
    }

    function confirmTransaction(uint256 _txIndex)
        external
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
        notConfirmed(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations += 1;
        isConfirmed[_txIndex][msg.sender] = true;

        emit ConfirmTransaction(msg.sender, _txIndex);
    }

    function executeTransaction(uint256 _txIndex) external onlyOwner txExists(_txIndex) notExecuted(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];

        if (transaction.numConfirmations < numConfirmationsRequired) {
            revert CannotExecuteTx();
        }

        // CEI Pattern: Update state BEFORE external call
        transaction.executed = true;

        (bool success,) = transaction.to.call{value: transaction.value}("");
        if (!success) revert TransferFailed();

        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    function revokeConfirmation(uint256 _txIndex) external onlyOwner txExists(_txIndex) notExecuted(_txIndex) {
        if (!isConfirmed[_txIndex][msg.sender]) revert TxNotConfirmed();

        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations -= 1;
        isConfirmed[_txIndex][msg.sender] = false;

        emit RevokeConfirmation(msg.sender, _txIndex);
    }

    // --- View Functions ---
    function getTransactionCount() public view returns (uint256) {
        return transactions.length;
    }
}
