pragma solidity 0.8.30;

contract WalletDummy {
    uint256 noteHash;
    address owner;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    event Transfer(address recipient, uint256 amount);

    constructor(uint256 _noteHash, address _owner) {
        noteHash = _noteHash;
        owner = _owner;
    }

    function getNoteHash() public view returns(uint256) {
        return noteHash;
    }

    function transfer(address recipient, uint256 amount) public onlyOwner {
        emit Transfer(recipient, amount);
    }
}

