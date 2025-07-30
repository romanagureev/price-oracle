# pragma version 0.4.3


struct ChainlinkData:
    roundID: uint80
    answer: int256
    startedAt: uint256
    updatedAt: uint256
    answeredInRound: uint80


# Mock data that can be set for testing
mock_answer: public(int256)
mock_updated_at: public(uint256)
mock_round_id: public(uint80)


@deploy
def __init__(_answer: int256, _updated_at: uint256):
    self.mock_answer = _answer
    self.mock_updated_at = _updated_at if _updated_at > 0 else block.timestamp
    self.mock_round_id = 1


@external
def set_mock_data(_answer: int256, _updated_at: uint256):
    self.mock_answer = _answer
    self.mock_updated_at = _updated_at


@external
@view
def latestRoundData() -> ChainlinkData:
    return ChainlinkData(
        roundID=self.mock_round_id,
        answer=self.mock_answer,
        startedAt=self.mock_updated_at,
        updatedAt=self.mock_updated_at,
        answeredInRound=self.mock_round_id,
    )
