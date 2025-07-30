# pragma version 0.4.3

from contracts.oracles import IPriceOracle

implements: IPriceOracle


struct PriceParameters:
    price: uint256
    confidence: uint256


# Mock data that can be set for testing
price: public(uint256)
confidence: public(uint256)


@deploy
def __init__(_price: uint256, _confidence: uint256):
    self.price = _price
    self.confidence = _confidence


@external
def set_mock_data(_price: uint256, _confidence: uint256):
    self.price = _price
    self.confidence = _confidence


@external
@view
def parameters() -> IPriceOracle.PriceParameters:
    return IPriceOracle.PriceParameters(
        price=self.price,
        confidence=self.confidence,
    )
