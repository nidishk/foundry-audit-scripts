// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

/**
 * @title AuditHelpers
 * @dev Utilities for smart contract auditing
 */
library AuditHelpers {
    function checkStorageSlot(address target, bytes32 slot) internal view returns (bytes32) {
        bytes32 value;
        assembly {
            value := sload(slot)
        }
        return value;
    }
    
    function computeStorageSlot(uint256 baseSlot, address key) internal pure returns (bytes32) {
        return keccak256(abi.encode(key, baseSlot));
    }
    
    function computeArraySlot(uint256 baseSlot, uint256 index) internal pure returns (bytes32) {
        return bytes32(uint256(keccak256(abi.encode(baseSlot))) + index);
    }
}

/**
 * @title GasProfiler
 * @dev Measures gas consumption of function calls
 */
contract GasProfiler {
    struct GasReport {
        string functionName;
        uint256 gasUsed;
        uint256 timestamp;
    }
    
    GasReport[] public reports;
    
    function profile(string memory name, address target, bytes memory data) external returns (uint256 gasUsed) {
        uint256 gasBefore = gasleft();
        (bool success,) = target.call(data);
        gasUsed = gasBefore - gasleft();
        
        require(success, "Call failed");
        reports.push(GasReport(name, gasUsed, block.timestamp));
    }
    
    function getReportCount() external view returns (uint256) {
        return reports.length;
    }
}

/**
 * @title StorageInspector
 * @dev Inspects contract storage layouts
 */
contract StorageInspector {
    function readSlot(address target, uint256 slot) external view returns (bytes32) {
        bytes32 value;
        assembly {
            mstore(0, slot)
            value := sload(mload(0))
        }
        return value;
    }
    
    function readMultipleSlots(address target, uint256 startSlot, uint256 count) external view returns (bytes32[] memory) {
        bytes32[] memory values = new bytes32[](count);
        for (uint256 i = 0; i < count; i++) {
            assembly {
                mstore(0, add(startSlot, i))
                mstore(add(values, mul(add(i, 1), 32)), sload(mload(0)))
            }
        }
        return values;
    }
}

/**
 * @title AccessControlChecker
 * @dev Checks access control patterns
 */
contract AccessControlChecker {
    function checkOwner(address target) external view returns (address) {
        (bool success, bytes memory data) = target.staticcall(abi.encodeWithSignature("owner()"));
        if (success && data.length == 32) {
            return abi.decode(data, (address));
        }
        return address(0);
    }
    
    function checkAdmin(address target) external view returns (address) {
        (bool success, bytes memory data) = target.staticcall(abi.encodeWithSignature("admin()"));
        if (success && data.length == 32) {
            return abi.decode(data, (address));
        }
        return address(0);
    }
    
    function checkPaused(address target) external view returns (bool) {
        (bool success, bytes memory data) = target.staticcall(abi.encodeWithSignature("paused()"));
        if (success && data.length == 32) {
            return abi.decode(data, (bool));
        }
        return false;
    }
}
