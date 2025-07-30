# pragma version 0.4.3

version: public(constant(String[8])) = "0.0.1"
oracle_type: public(constant(String[16])) = "Chained"

from snekmate.utils import math

import IPriceOracle

implements: IPriceOracle

MAX_LEN: constant(uint256) = 4
CHAIN_OF_ORACLES: public(immutable(DynArray[IPriceOracle, MAX_LEN]))


@deploy
def __init__(_chain: DynArray[IPriceOracle, MAX_LEN]):
    CHAIN_OF_ORACLES = _chain


@view
def _get_price() -> uint256:
    price: uint256 = 10**18
    for oracle: IPriceOracle in CHAIN_OF_ORACLES:
        price = (price * staticcall oracle.price()) // 10**18
    return price


@view
def _get_confidence() -> uint256:
    confidence: uint256 = 10**18
    for oracle: IPriceOracle in CHAIN_OF_ORACLES:
        confidence = (confidence * staticcall oracle.confidence()) // 10**18
    return confidence


@view
def _get_parameters() -> IPriceOracle.PriceParameters:
    return IPriceOracle.PriceParameters(
        price=self._get_price(),
        confidence=self._get_confidence(),
    )


@external
@view
def price() -> uint256:
    return self._get_price()


@external
@view
def confidence() -> uint256:
    return self._get_confidence()


@external
@view
def parameters() -> IPriceOracle.PriceParameters:
    return self._get_parameters()
