# pragma version 0.4.3

from snekmate.utils import math

import IPriceOracle

implements: IPriceOracle


interface ICurvePool:
    def price_oracle(i: uint256 = 0) -> uint256: view
    def ema_tvl() -> uint256: view
    def coins(i: uint256) -> address: view


POOL: public(immutable(ICurvePool))
TOKEN: public(immutable(address))

I: immutable(uint256)
NO_ARGUMENT: immutable(bool)

TARGET_TVL: public(immutable(uint256))
K: constant(int256) = 10**18
DENOMINATOR: immutable(uint256)


@deploy
def __init__(_pool: ICurvePool, _token: address, _target_tvl: uint256):
    POOL = _pool
    TOKEN = _token

    for i: uint256 in range(8):
        coin: address = staticcall _pool.coins(i)
        if coin == _token:
            I = i
    success: bool = raw_call(
        _pool.address,
        abi_encode(convert(0, uint256), method_id=method_id("price_oracle(uint256)")),
        revert_on_failure=False,
    )
    NO_ARGUMENT = not success
    if NO_ARGUMENT:
        assert I < 2, "Pool hallucinates"

    assert 10**18 <= _target_tvl and _target_tvl <= 10**36, "Bad TVL value"
    TARGET_TVL = _target_tvl
    DENOMINATOR = 10**18 - convert(math._wad_exp(K * 10**18), uint256)


@view
def _get_price() -> uint256:
    if NO_ARGUMENT:
        if I == 0:
            return 10**36 // staticcall POOL.price_oracle()
        else:
            return staticcall POOL.price_oracle()
    if I == 0:
        return 10**36 // staticcall POOL.price_oracle(0)
    return staticcall POOL.price_oracle(I)


@view
def _get_confidence() -> uint256:
    ema_tvl: uint256 = staticcall POOL.ema_tvl()
    if ema_tvl >= TARGET_TVL:
        return 10**18

    return (
        10**18
        - convert(math._wad_exp(-K * convert(ema_tvl * 10**18 // TARGET_TVL, int256)), uint256)
    ) * 10**18 // DENOMINATOR


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
