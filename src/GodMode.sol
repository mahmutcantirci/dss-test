// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2021 Dai Foundation
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

import {WardsAbstract,DSTokenAbstract,DaiAbstract} from "dss-interfaces/Interfaces.sol";

// NOTE this contains some extra Foundry-only calls
// If using DappTools check if things are available
interface Vm {
    // Set block.timestamp (newTimestamp)
    function warp(uint256) external;
    // Set block.height (newHeight)
    function roll(uint256) external;
    // Loads a storage slot from an address (who, slot)
    function load(address,bytes32) external returns (bytes32);
    // Stores a value to an address' storage slot, (who, slot, value)
    function store(address,bytes32,bytes32) external;
    // Signs data, (privateKey, digest) => (r, v, s)
    function sign(uint256,bytes32) external returns (uint8,bytes32,bytes32);
    // Gets address for a given private key, (privateKey) => (address)
    function addr(uint256) external returns (address);
    // Performs a foreign function call via terminal, (stringInputs) => (result)
    function ffi(string[] calldata) external returns (bytes memory);
    // Performs the next smart contract call with specified `msg.sender`, (newSender)
    function prank(address) external;
    // Performs all the following smart contract calls with specified `msg.sender`, (newSender)
    function startPrank(address) external;
    // Stop smart contract calls using the specified address with prankStart()
    function stopPrank() external;
    // Sets an address' balance, (who, newBalance)
    function deal(address, uint256) external;
    // Sets an address' code, (who, newCode)
    function etch(address, bytes calldata) external;
    // Expects an error on next call
    function expectRevert(bytes calldata) external;
    // Expects the next emitted event. Params check topic 1, topic 2, topic 3 and data are the same.
    function expectEmit(bool, bool, bool, bool) external;
    // Mocks a call to an address, returning specified data.
    // Calldata can either be strict or a partial match, e.g. if you only
    // pass a Solidity selector to the expected calldata, then the entire Solidity
    // function will be mocked.
    function mockCall(address,bytes calldata,bytes calldata) external;
    // Clears all mocked calls
    function clearMockedCalls() external;
    // Expect a call to an address with the specified calldata.
    // Calldata can either be strict or a partial match
    function expectCall(address,bytes calldata) external;
}

library GodMode {
    
    address constant public VM_ADDR = address(bytes20(uint160(uint256(keccak256('hevm cheat code')))));

    function vm() internal view returns (Vm) {
        return Vm(VM_ADDR);
    }

    /// @dev Gives `target` contract admin access on the `base`
    function giveAuthAccess(address base, address target) internal {
        // Edge case - ward is already set
        if (WardsAbstract(base).wards(target) == 1) return;

        for (int i = 0; i < 100; i++) {
            // Scan the storage for the ward storage slot
            bytes32 prevValue = vm().load(
                address(base),
                keccak256(abi.encode(target, uint256(i)))
            );
            vm().store(
                address(base),
                keccak256(abi.encode(target, uint256(i))),
                bytes32(uint256(1))
            );
            if (WardsAbstract(base).wards(target) == 1) {
                // Found it
                return;
            } else {
                // Keep going after restoring the original value
                vm().store(
                    address(base),
                    keccak256(abi.encode(target, uint256(i))),
                    prevValue
                );
            }
        }

        // We have failed if we reach here
        revert("Could not give auth access");
    }

    /// @dev Gives `target` contract admin access on the `base`
    function giveAuthAccess(WardsAbstract base, address target) internal {
        giveAuthAccess(address(base), target);
    }

    /// @dev Sets the balance for `who` to `amount` for `token`.
    function setBalance(address token, address who, uint256 amount) internal {
        // Edge case - balance is already set for some reason
        if (DSTokenAbstract(token).balanceOf(who) == amount) return;

        for (uint256 i = 0; i < 200; i++) {
            // Scan the storage for the balance storage slot
            bytes32 prevValue = vm().load(
                token,
                keccak256(abi.encode(who, uint256(i)))
            );
            vm().store(
                token,
                keccak256(abi.encode(who, uint256(i))),
                bytes32(amount)
            );
            if (DSTokenAbstract(token).balanceOf(who) == amount) {
                // Found it
                return;
            } else {
                // Keep going after restoring the original value
                vm().store(
                    token,
                    keccak256(abi.encode(who, uint256(i))),
                    prevValue
                );
            }
        }

        // We have failed if we reach here
        revert("Could not give tokens");
    }

    /// @dev Sets the balance for `who` to `amount` for `token`.
    function setBalance(DSTokenAbstract token, address who, uint256 amount) internal {
        setBalance(address(token), who, amount);
    }

    /// @dev Sets the balance for `who` to `amount` for `token`.
    function setBalance(DaiAbstract token, address who, uint256 amount) internal {
        setBalance(address(token), who, amount);
    }

}