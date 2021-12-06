// SPDX-License-Identifier: MIT

// testERC721Receiver
//
// Dummy contracts that 


pragma solidity >=0.7.6 ;

contract testERC721Receiver {

   bool private answer;

   constructor (bool _answer) {
       answer = _answer;
   }

   function onERC721Received(address, address, uint256, bytes calldata) external returns(bytes4) {
       if (answer == true) {
           //return 0xf0b9e5ba;
           return testERC721Receiver.onERC721Received.selector;
           //return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
       } else {
           return 0xdeadbeef;
       }
   }

}

contract revertsERC721Receiver {
   function onERC721Received(address a, address b, uint256 c, bytes calldata) external returns(bytes4) {
      if (c > 100) {
         revert ("Always reverts") ; }
      else {
         revert ("Always reverts");
      }
   }

}
