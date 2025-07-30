# pragma version 0.4.3

version: public(constant(String[8])) = "0.0.1"
oracle_type: public(constant(String[16])) = "Weighted"

import IPriceOracle
implements: IPriceOracle

from contracts.utils import ManagedAdmin as admin
from contracts.utils import WeightRamping as weight_ramping
from contracts.utils.weight_calculators import AverageCalculator as calculator

initializes: admin
initializes: weight_ramping
exports: (
    admin.transfer_ownership,
    admin.add_manager,
    admin.remove_manager,
)


event AddPriceOracle:
    oracle: IPriceOracle


event RemovePriceOracle:
    oracle: IPriceOracle


price_oracles: DynArray[IPriceOracle, calculator.MAX_ORACLES]


@deploy
def __init__(_price_oracles: DynArray[IPriceOracle, calculator.MAX_ORACLES]):
    for oracle: IPriceOracle in _price_oracles:
        assert self._check_oracle(oracle), "Bad price oracle"
        self.price_oracles.append(oracle)
        log AddPriceOracle(oracle=oracle)

    admin.__init__()
    weight_ramping.__init__()


#@external
# def __fallback__() -> uint256:  # TODO: is it a good idea?
#    assert len(msg.data) == 4, "Not a view"
#    return self._price()


@view
def _fetch_parameters() -> DynArray[IPriceOracle.PriceParameters, calculator.MAX_ORACLES]:
    oracle_params: DynArray[IPriceOracle.PriceParameters, calculator.MAX_ORACLES] = empty(
        DynArray[IPriceOracle.PriceParameters, calculator.MAX_ORACLES]
    )
    for i: uint256 in range(len(self.price_oracles), bound=calculator.MAX_ORACLES):
        oracle: IPriceOracle = self.price_oracles[i]
        oracle_params.append(staticcall oracle.parameters())
        oracle_params[i].confidence = weight_ramping._calculate_weight(
            oracle.address, min(oracle_params[i].confidence, calculator.MAX_CONFIDENCE)
        )
    return oracle_params


@external
@view
def price() -> uint256:
    return calculator._get_price(self._fetch_parameters())


@external
@view
def price_bounds() -> (uint256, uint256):
    return calculator._get_bounds(self._fetch_parameters())


@external
@view
def confidence() -> uint256:
    return calculator._get_confidence(self._fetch_parameters())


@external
@view
def parameters() -> IPriceOracle.PriceParameters:
    return calculator._get_parameters(self._fetch_parameters())


@external
def clean_price_oracle():
    new_price_oracles: DynArray[IPriceOracle, calculator.MAX_ORACLES] = empty(
        DynArray[IPriceOracle, calculator.MAX_ORACLES]
    )
    for oracle: IPriceOracle in self.price_oracles:
        if weight_ramping._get_weight(oracle.address) > 0:
            new_price_oracles.append(oracle)
        else:
            weight_ramping._remove_operand(oracle.address)
            log RemovePriceOracle(oracle=oracle)
    self.price_oracles = new_price_oracles


@external
def ramp_oracle_weight(
    _oracle: IPriceOracle, _future_weight: uint256, _duration: uint256, _force: bool = False
):
    admin._check_manager()
    if _force:
        admin._check_owner()
    assert _oracle in self.price_oracles, "Unknown oracle"

    weight_ramping._ramp_weight(_oracle.address, _future_weight, _duration, _force)


@external
def set_ramping_limits(_min_weight: uint256, _max_weight: uint256, _max_weight_ramp: uint256):
    admin._check_owner()
    weight_ramping._set_limits(_min_weight, _max_weight, _max_weight_ramp)


@view
def _check_oracle(oracle: IPriceOracle) -> bool:
    price: uint256 = staticcall oracle.price()
    confidence: uint256 = staticcall oracle.confidence()
    parameters: IPriceOracle.PriceParameters = staticcall oracle.parameters()
    return price == parameters.price and confidence == parameters.confidence and confidence > 0


@external
def add_price_oracles(_new_price_oracles: DynArray[IPriceOracle, calculator.MAX_ORACLES]):
    admin._check_manager()

    for oracle: IPriceOracle in _new_price_oracles:
        if oracle not in self.price_oracles:
            assert self._check_oracle(oracle), "Bad price oracle"
            self.price_oracles.append(oracle)
            log AddPriceOracle(oracle=oracle)


@external
def remove_price_oracles(_unwanted_price_oracles: DynArray[IPriceOracle, calculator.MAX_ORACLES]):
    admin._check_owner()

    new_price_oracles: DynArray[IPriceOracle, calculator.MAX_ORACLES] = empty(
        DynArray[IPriceOracle, calculator.MAX_ORACLES]
    )
    for oracle: IPriceOracle in self.price_oracles:
        if oracle not in _unwanted_price_oracles:
            new_price_oracles.append(oracle)
        else:
            weight_ramping._remove_operand(oracle.address)
            log RemovePriceOracle(oracle=oracle)
    assert len(new_price_oracles) > 0, "Need at least one oracle"
    self.price_oracles = new_price_oracles
