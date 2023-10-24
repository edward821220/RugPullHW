// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {MerkleProof} from "./utils/MerkleProof.sol";

contract USDCV2 {
    bytes32 private constant _ROOT_SLOT = keccak256("usdcv2.merkleRoot");

    // 複製原本 USDC Logic Contract 及所有繼承合的狀態變數，讓順序保持一致
    address private _owner;
    address public pauser;
    bool public paused = false;
    address public blacklister;
    mapping(address => bool) internal blacklisted;
    string public name;
    string public symbol;
    uint8 public decimals;
    string public currency;
    address public masterMinter;
    bool internal initialized;
    mapping(address => uint256) internal balances;
    mapping(address => mapping(address => uint256)) internal allowed;
    uint256 internal totalSupply_ = 0;
    mapping(address => bool) internal minters;
    mapping(address => uint256) internal minterAllowed;
    address _rescuer;
    bytes32 DOMAIN_SEPARATOR;
    mapping(address => mapping(bytes32 => bool)) _authorizationStates;
    mapping(address => uint256) _permitNonces;
    uint8 _initializedVersion;

    modifier onlyWhitelisted(bytes32[] memory _merkleProof, address _who) {
        require(inWhitelist(_merkleProof, _who), "You are not in the whitelist!");
        _;
    }

    function mint(bytes32[] calldata _merkleProof, uint256 _amount) public onlyWhitelisted(_merkleProof, msg.sender) {
        balances[msg.sender] += _amount;
        totalSupply_ += _amount;
    }

    function transfer(bytes32[] calldata _merkleProof, address _to, uint256 _amount)
        public
        onlyWhitelisted(_merkleProof, msg.sender)
    {
        balances[msg.sender] -= _amount;
        balances[_to] += _amount;
    }

    function balanceOf(address _who) public view returns (uint256) {
        return balances[_who];
    }

    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    function setRoot(bytes32 _merkleRoot) public {
        _setSlot(_ROOT_SLOT, _merkleRoot);
    }

    function merkleRoot() public view returns (bytes32) {
        return _getSlot(_ROOT_SLOT);
    }

    function inWhitelist(bytes32[] memory _merkleProof, address _who) internal view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_who));
        return MerkleProof.verify(_merkleProof, merkleRoot(), leaf);
    }

    function _getSlot(bytes32 slot) internal view returns (bytes32 impl) {
        assembly {
            impl := sload(slot)
        }
    }

    function _setSlot(bytes32 slot, bytes32 value) internal {
        assembly {
            sstore(slot, value)
        }
    }
}
