// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/AuditTools.sol";

contract TargetContract {
    address public owner;
    bool public paused;
    uint256 public value;
    
    constructor() {
        owner = msg.sender;
    }
    
    function setValue(uint256 _value) external {
        value = _value;
    }
    
    function pause() external {
        paused = true;
    }
}

contract GasProfilerTest is Test {
    GasProfiler profiler;
    TargetContract target;

    function setUp() public {
        profiler = new GasProfiler();
        target = new TargetContract();
    }

    function testProfile() public {
        bytes memory data = abi.encodeWithSignature("setValue(uint256)", 100);
        uint256 gasUsed = profiler.profile("setValue", address(target), data);
        
        assertGt(gasUsed, 0);
        assertEq(profiler.getReportCount(), 1);
    }

    function testMultipleProfiles() public {
        bytes memory data1 = abi.encodeWithSignature("setValue(uint256)", 100);
        bytes memory data2 = abi.encodeWithSignature("setValue(uint256)", 200);
        
        profiler.profile("setValue1", address(target), data1);
        profiler.profile("setValue2", address(target), data2);
        
        assertEq(profiler.getReportCount(), 2);
    }
}

contract AccessControlCheckerTest is Test {
    AccessControlChecker checker;
    TargetContract target;

    function setUp() public {
        checker = new AccessControlChecker();
        target = new TargetContract();
    }

    function testCheckOwner() public view {
        address owner = checker.checkOwner(address(target));
        assertEq(owner, address(this));
    }

    function testCheckPaused() public {
        assertFalse(checker.checkPaused(address(target)));
        target.pause();
        assertTrue(checker.checkPaused(address(target)));
    }

    function testCheckAdminNotExists() public view {
        address admin = checker.checkAdmin(address(target));
        assertEq(admin, address(0));
    }
}

contract StorageInspectorTest is Test {
    StorageInspector inspector;
    TargetContract target;

    function setUp() public {
        inspector = new StorageInspector();
        target = new TargetContract();
    }

    function testReadSlotFromSelf() public {
        target.setValue(12345);
        uint256 storedValue = target.value();
        assertEq(storedValue, 12345);
    }
}
