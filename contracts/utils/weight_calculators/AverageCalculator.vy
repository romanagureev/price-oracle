# pragma version 0.4.3

from contracts.oracles import IPriceOracle as ps

# Only external functions, but
# implements: IWeightedPriceCalculator
# Also Vyper does not support importing from .vyi
MAX_ORACLES: constant(uint256) = 4
MAX_CONFIDENCE: constant(uint256) = 10**18


@view
def _get_price(parameters: DynArray[ps.PriceParameters, MAX_ORACLES]) -> uint256:
    total_sum: uint256 = 0
    total_weight: uint256 = 0
    for params: ps.PriceParameters in parameters:
        total_sum += params.confidence * params.price
        total_weight += params.confidence

    return total_sum // total_weight


@view
def _get_bounds(parameters: DynArray[ps.PriceParameters, MAX_ORACLES]) -> (uint256, uint256):
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
def _get_confidence(parameters: DynArray[ps.PriceParameters, MAX_ORACLES]) -> uint256:
    error: uint256 = 10**18
    for params: ps.PriceParameters in parameters:
        error = error * (10**18 - params.confidence) // 10**18
    return 10**18 - error


@view
def _get_parameters(parameters: DynArray[ps.PriceParameters, MAX_ORACLES]) -> ps.PriceParameters:
    return ps.PriceParameters(
        price=self._get_price(parameters),
        confidence=self._get_confidence(parameters),
    )
