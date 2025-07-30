# pragma version 0.4.3


struct WeightData:
    w0: uint256  # initial weight
    w1: uint256  # future weight
    t0: uint256  # initial time
    t1: uint256  # future time


MAX_WEIGHT: constant(uint256) = 10**18

# Manager's restrictions
min_weight: uint256
max_weight: uint256
max_weight_ramp: uint256  # per sec

weight_data: HashMap[address, WeightData]


@deploy
def __init__():
    self.min_weight = MAX_WEIGHT // 2
    self.max_weight = MAX_WEIGHT // 2
    # 0.5 bps per block
    # 0.0005 per 12 sec
    self.max_weight_ramp = 5 * MAX_WEIGHT // 100_00 // 12


@view
def _get_weight(operand: address) -> uint256:
    d: WeightData = self.weight_data[operand]
    if block.timestamp > d.t1:
        return d.w1

    return (d.w0 * (d.t1 - block.timestamp) + d.w1 * (block.timestamp - d.t0)) // (d.t1 - d.t0)


@view
def _calculate_weight(operand: address, variable: uint256) -> uint256:
    return self._get_weight(operand) * variable // MAX_WEIGHT


def _ramp_weight(operand: address, future_weight: uint256, duration: uint256, force: bool = False):
    assert future_weight <= MAX_WEIGHT, "Bad weight"

    current_weight: uint256 = self._get_weight(operand)
    if not force:
        assert (
            self.min_weight <= future_weight and future_weight <= self.max_weight
        ), "Weight value out of bounds"
        assert (
            unsafe_sub(2 * current_weight, future_weight) <= duration * self.max_weight_ramp
        ), "Ramping too fast"

    self.weight_data[operand] = WeightData(
        w0=current_weight,
        w1=future_weight,
        t0=block.timestamp,
        t1=block.timestamp + duration,
    )


def _remove_operand(operand: address):
    self.weight_data[operand] = empty(WeightData)


def _set_limits(min_weight: uint256, max_weight: uint256, max_weight_ramp: uint256):
    assert min_weight <= max_weight and max_weight <= MAX_WEIGHT, "Bad weight value"
    assert max_weight_ramp <= MAX_WEIGHT, "Bad ramp velocity"

    self.min_weight = min_weight
    self.max_weight = max_weight
    self.max_weight_ramp = max_weight_ramp
