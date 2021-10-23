#!/usr/env python
#
# Test that the ERC721 receiver test contract 
# returns the values it should return.

import pytest
import logging
import web3
from brownie import accounts, testERC721Receiver, exceptions, reverts, ZERO_ADDRESS

    
def test_dumyERC721Receiver():

    alice, bob = [ x.address for x in accounts[0:2]]

    # This contract always fails
    receiver = accounts[0].deploy(testERC721Receiver, False)
    tx = receiver.onERC721Received(alice, bob, 123, b"ig.no.red")
    
    assert tx.return_value == web3.types.HexStr("0x00000000")

    # This contract always succeeds
    receiver2 = accounts[0].deploy(testERC721Receiver, True)
    tx = receiver2.onERC721Received(alice, bob, 123, b"ig.no.red")
    assert tx.return_value == web3.types.HexStr("0x150b7a02")
