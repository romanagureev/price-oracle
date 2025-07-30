# pragma version 0.4.3

from snekmate.utils import math
from contracts.oracles import IPriceOracle as ps

# Only external functions, but
# implements: IWeightedPriceCalculator
# Also Vyper does not support importing from .vyi
MAX_ORACLES: constant(uint256) = 4
MAX_CONFIDENCE: constant(uint256) = 10**18

SIGMA: constant(uint256) = 10**18  # TODO


@view
def _get_price(parameters: DynArray[ps.PriceParameters, MAX_ORACLES]) -> uint256:
    w_sum: uint256 = 0
    wp_sum: uint256 = 0
    for params: ps.PriceParameters in parameters:
        wp_sum += params.confidence * params.price
        w_sum += params.confidence

    p_avg: uint256 = wp_sum // w_sum
    e: DynArray[uint256, MAX_ORACLES] = empty(DynArray[uint256, MAX_ORACLES])
    e_min: uint256 = max_value(uint256)
    for params: ps.PriceParameters in parameters:
        new_e: uint256 = (max(params.price, p_avg) - min(params.price, p_avg))**2 // (
            SIGMA**2 // 10**18
        )
        e.append(new_e)
        e_min = min(new_e, e_min)

    wp_sum = 0
    w_sum = 0
    for i: uint256 in range(len(parameters), bound=MAX_ORACLES):
        w: uint256 = (
            parameters[i].confidence
            * convert(math._wad_exp(-convert(e[i] - e_min, int256)), uint256) // 10**18
        )
        w_sum += w
        wp_sum += w * parameters[i].price
    return wp_sum // w_sum


@view
def _get_bounds(
    parameters: DynArray[ps.PriceParameters, MAX_ORACLES]
) -> (uint256, uint256):  # TODO
    mean_price: uint256 = self._get_price(parameters)
    total_sum: uint256 = 0
    total_weight: uint256 = 0
    for params: ps.PriceParameters in parameters:
        abs_diff: uint256 = (
            params.price - mean_price if params.price > mean_price else mean_price - params.price
        )
        total_sum += params.confidence * abs_diff**2
        total_weight += params.confidence

    var: uint256 = isqrt(total_sum // total_weight)
    return mean_price - var, mean_price + var


@view
def _get_confidence(_parameters: DynArray[ps.PriceParameters, MAX_ORACLES]) -> uint256:
    error: uint256 = 10**18
    for params: ps.PriceParameters in _parameters:
        error = error * (10**18 - params.confidence) // 10**18
    return 10**18 - error


@view
def _get_parameters(_parameters: DynArray[ps.PriceParameters, MAX_ORACLES]) -> ps.PriceParameters:
    return ps.PriceParameters(
        price=self._get_price(_parameters),
        confidence=self._get_confidence(_parameters),
    )
