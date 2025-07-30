# Chain several price sources
# pragma version 0.4.3

from snekmate.utils import math

import IPriceOracle

implements: IPriceOracle


struct Adjustment:
    MUL: uint256
    DIV: uint256


SOURCE: public(immutable(address))
METHOD_ID: public(immutable(Bytes[4]))

# Adjustment to 10 ** 18 precision
ADJUSTMENT: public(immutable(Adjustment))


@deploy
def __init__(_source: address, _method_id: Bytes[4], _adjustment: Adjustment):
    SOURCE = _source
    METHOD_ID = _method_id

    ADJUSTMENT = _adjustment


@view
def _get_price() -> uint256:
    rate: uint256 = convert(
        raw_call(
            SOURCE,
            METHOD_ID,
            is_static_call=True,
            max_outsize=32,
        ),
        uint256,
    )
    return rate * ADJUSTMENT.MUL // ADJUSTMENT.DIV


@view
def _get_confidence() -> uint256:
    return 10**18


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
