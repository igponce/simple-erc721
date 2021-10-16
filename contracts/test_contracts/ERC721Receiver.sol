// SPDX-License-Identifier: MIT

// testERC721Receiver
//
// Dummy contracts that 


pragma solidity >=0.8.4 ;

contract testERC721Receiver {

   bool private receiveFails;

   constructor (bool _receiveFails) {
       receiveFails = _receiveFails;
   }

   function onERC721Received(address, address, uint256, bytes calldata) external view returns(bytes4) {
       if (receiveFails) {
           return 0;
       } else {
           return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
       }
   }

}
