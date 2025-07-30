# pragma version 0.4.3

version: public(constant(String[8])) = "0.0.1"
oracle_type: public(constant(String[16])) = "Chainlink"

from snekmate.utils import math

import IPriceOracle

implements: IPriceOracle


struct ChainlinkData:
    roundID: uint80
    answer: int256
    startedAt: uint256
    updatedAt: uint256
    answeredInRound: uint80


interface IAggregatorV3Interface:
    def latestRoundData() -> ChainlinkData: view


PRICE_FEED: public(immutable(IAggregatorV3Interface))
MAX_STALENESS: public(immutable(uint256))

# return epsilon when max_staleness reached
# ln(epsilon) = ln(0.01) \approx 4
LN_EPS: constant(int256) = -4 * 10**18
# K = - ln(epsilon) / MAX_STALENESS
K: immutable(int256)

# Good to store per one block for gas purposes and sandwich protection
# cl_data: transient(ChainlinkData)  # TODO: what if not cancun?


@deploy
def __init__(_price_feed: IAggregatorV3Interface, _max_staleness: uint256):
    PRICE_FEED = _price_feed

    assert 60 <= _max_staleness and _max_staleness <= 3 * 86400, "Bad max staleness"
    MAX_STALENESS = _max_staleness
    K = -LN_EPS * 10**18 // convert(MAX_STALENESS, int256)


@view
def _get_price(cl_data: ChainlinkData = empty(ChainlinkData)) -> uint256:
    if cl_data.updatedAt == 0:
        cl_data = staticcall PRICE_FEED.latestRoundData()

    return convert(cl_data.answer, uint256)


@view
def _get_confidence(cl_data: ChainlinkData = empty(ChainlinkData)) -> uint256:
    if cl_data.updatedAt == 0:
        cl_data = staticcall PRICE_FEED.latestRoundData()
    staleness: int256 = convert(block.timestamp - cl_data.updatedAt, int256)
    return convert(math._wad_exp(-K * staleness), uint256)


@view
def _get_parameters() -> IPriceOracle.PriceParameters:
    cl_data: ChainlinkData = staticcall PRICE_FEED.latestRoundData()
    return IPriceOracle.PriceParameters(
        price=self._get_price(cl_data),
        confidence=self._get_confidence(cl_data),
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
