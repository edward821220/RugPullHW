// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "solmate/tokens/ERC20.sol";
import {Merkle} from "../src/utils/Merkle.sol";
import {USDCV2} from "../src/USDCV2.sol";

interface IUSDC {
    function upgradeTo(address newImplementation) external;
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable;
    function implementation() external view returns (address);
    function changeAdmin(address newAdmin) external;
    function admin() external view returns (address);

    event AdminChanged(address previousAdmin, address newAdmin);
    event Upgraded(address implementation);
}

contract USDCTest is Test {
    address owner;
    // Users in whitelist
    address alice = makeAddr("Alice");
    address bob = makeAddr("Bob");
    uint256 aliceIndex = 0;
    uint256 bobIndex = 1;

    // Users not in whitelist
    address carol = makeAddr("Carol");

    // Contracts
    IUSDC usdc;

    // Merkle Tree
    Merkle merkleTree;
    bytes32[] public leaf;
    bytes32 public root;

    function setUp() public {
        // Fork mainnet
        uint256 forkId = vm.createFork("https://eth-mainnet.g.alchemy.com/v2/jPQVBwnGCpqJr_q90JyNyy70mjuYdlRx");
        vm.selectFork(forkId);

        // Get USDC's admin and set the address to owner
        usdc = IUSDC(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
        bytes32 usdcAdmin = vm.load(address(usdc), 0x10d6a54a4754c8869d6886b5f5d7fbfa5b4522237ea5c60d11bc4e7a1ff9390b);
        owner = address(uint160(uint256(usdcAdmin)));

        // Make merkle leaf (whitelist address)
        merkleTree = new Merkle();
        leaf = new bytes32[](2);
        leaf[aliceIndex] = keccak256(abi.encodePacked(alice));
        leaf[bobIndex] = keccak256(abi.encodePacked(bob));
        root = merkleTree.getRoot(leaf);
    }

    function testUpgrade() public {
        // Pretend that you are proxy owner
        vm.startPrank(owner);
        // Upgrade USDC to USDCV2
        USDCV2 usdcV2Logic = new USDCV2();
        usdc.upgradeTo(address(usdcV2Logic));
        USDCV2 usdcV2 = USDCV2(address(usdc));
        vm.stopPrank();

        // 換一個 user 來執行 setRoot 確定有升級成功 (admin 不能執行 logic contract 的 function)
        vm.prank(alice);
        usdcV2.setRoot(root);
    }

    function testWhitelist() public {
        // Pretend that you are proxy owner
        vm.startPrank(owner);
        // Upgrade USDC to USDCV2
        USDCV2 usdcV2Logic = new USDCV2();
        usdc.upgradeTo(address(usdcV2Logic));
        USDCV2 usdcV2 = USDCV2(address(usdc));
        vm.stopPrank();

        // 用在白名單里的 Alice 來測試
        vm.startPrank(alice);
        // setRoot 設定白名單
        usdcV2.setRoot(root);
        bytes32[] memory aliceProof = merkleTree.getProof(leaf, aliceIndex);

        // 先 Mint 後的餘額跟總量都有增加
        uint256 totalSupllyBefore = usdcV2.totalSupply();
        uint256 mintAmount = 10000000000;
        usdcV2.mint(aliceProof, mintAmount);
        assertEq(usdcV2.balanceOf(alice), mintAmount);
        assertEq(usdcV2.totalSupply(), totalSupllyBefore + mintAmount);

        // 測試 Transfer
        usdcV2.transfer(aliceProof, bob, 6666666);
        assertEq(usdcV2.balanceOf(bob), 6666666);

        vm.stopPrank();

        // 用不在白名單里的 Carol 來測試
        vm.startPrank(carol);
        vm.expectRevert("You are not in the whitelist!");
        usdcV2.mint(aliceProof, 10000000000);
        vm.expectRevert("You are not in the whitelist!");
        usdcV2.transfer(aliceProof, bob, 500);
        vm.stopPrank();
    }
}
