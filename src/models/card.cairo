#[derive(Copy, Drop, Serde, Debug)]
#[dojo::model]
pub struct CommunityCards {
    #[key]
    pub table_id: u32,
    pub flop1: u8,
    pub flop2: u8,
    pub flop3: u8,
    pub turn: u8,
    pub river: u8,
    // 0=none, 3=flop, 4=turn, 5=river
    pub cards_dealt: u8 
}

#[derive(Copy, Drop, Serde, Debug)]
#[dojo::model]
pub struct GameDeck {
    #[key]
    pub table_id: u32,
    pub cards: Span<u8>, // Shuffled deck
    pub next_card_index: u8,
    pub seed: u256
}

#[derive(Copy, Drop, Serde, PartialEq)]
pub struct Card {
    pub suit: CardSuits,
    pub rank: CardRank,
}

#[derive(Serde, Copy, Drop, Introspect, PartialEq, Debug)]
pub enum CardSuits {
    Spades,
    Hearts,
    Diamonds,
    Clubs,
}

impl CardSuitsIntoU8 of Into<CardSuits, u8> {
    fn into(self: CardSuits) -> u8 {
        match self {
            CardSuits::Spades => 0,
            CardSuits::Hearts => 1,
            CardSuits::Diamonds => 2,
            CardSuits::Clubs => 3,
        }
    }
}

impl U8TryIntoCardSuits of TryInto<u8, CardSuits> {
    fn try_into(self: u8) -> Option<CardSuits> {
        if self == 0 {
            Option::Some(CardSuits::Spades)
        } else if self == 1 {
            Option::Some(CardSuits::Hearts)
        } else if self == 2 {
            Option::Some(CardSuits::Diamonds)
        } else if self == 3 {
            Option::Some(CardSuits::Clubs)
        } else {
            Option::None
        }
    }
}

#[derive(Serde, Copy, Drop, Introspect, PartialEq, Debug)]
pub enum CardRank {
    Two,
    Three,
    Four,
    Five,
    Six,
    Seven,
    Eight,
    Nine,
    Ten,
    Jack,
    Queen,
    King,
    Ace,
}

impl CardRankIntoU8 of Into<CardRank, u8> {
    fn into(self: CardRank) -> u8 {
        match self {
            CardRank::Two => 0,
            CardRank::Three => 1,
            CardRank::Four => 2,
            CardRank::Five => 3,
            CardRank::Six => 4,
            CardRank::Seven => 5,
            CardRank::Eight => 6,
            CardRank::Nine => 7,
            CardRank::Ten => 8,
            CardRank::Jack => 9,
            CardRank::Queen => 10,
            CardRank::King => 11,
            CardRank::Ace => 12,
        }
    }
}

impl U8TryIntoCardRank of TryInto<u8, CardRank> {
    fn try_into(self: u8) -> Option<CardRank> {
        if self == 0 {
            Option::Some(CardRank::Two)
        } else if self == 1 {
            Option::Some(CardRank::Three)
        } else if self == 2 {
            Option::Some(CardRank::Four)
        } else if self == 3 {
            Option::Some(CardRank::Five)
        } else if self == 4 {
            Option::Some(CardRank::Six)
        } else if self == 5 {
            Option::Some(CardRank::Seven)
        } else if self == 6 {
            Option::Some(CardRank::Eight)
        } else if self == 7 {
            Option::Some(CardRank::Nine)
        } else if self == 8 {
            Option::Some(CardRank::Ten)
        } else if self == 9 {
            Option::Some(CardRank::Jack)
        } else if self == 10 {
            Option::Some(CardRank::Queen)
        } else if self == 11 {
            Option::Some(CardRank::King)
        } else if self == 12 {
            Option::Some(CardRank::Ace)
        } else {
            Option::None
        }
    }
}


#[generate_trait]
pub impl CardImpl of CardTrait {
    fn from_index(index: u8) -> Card {
        assert(index < 52, 'Invalid card index');
        Card { suit: Self::get_card_suit(index), rank: Self::get_card_rank(index) }
    }

    fn to_index(card: Card) -> u8 {
        let suit_value: u8 = card.suit.into();
        let rank_value: u8 = card.rank.into();
        suit_value * 13 + rank_value
    }

    fn get_card_suit(card: u8) -> CardSuits {
        assert(card < 52, 'Invalid card index');
        (card / 13).try_into().unwrap()
    }

    fn get_card_rank(card: u8) -> CardRank {
        assert(card < 52, 'Invalid card index');
        (card % 13).try_into().unwrap()
    }

    fn card_value(rank: CardRank) -> u8 {
        match rank {
            CardRank::Ace => 14,
            CardRank::Two => 2,
            CardRank::Three => 3,
            CardRank::Four => 4,
            CardRank::Five => 5,
            CardRank::Six => 6,
            CardRank::Seven => 7,
            CardRank::Eight => 8,
            CardRank::Nine => 9,
            CardRank::Ten => 10,
            CardRank::Jack => 11,
            CardRank::Queen => 12,
            CardRank::King => 13,
        }
    }

    fn is_ace(rank: CardRank) -> bool {
        rank == CardRank::Ace
    }

    fn is_face_card(rank: CardRank) -> bool {
        match rank {
            CardRank::Jack | CardRank::Queen | CardRank::King => true,
            _ => false,
        }
    }

    fn card_value_ace_low(rank: CardRank) -> u8 {
        match rank {
            CardRank::Ace => 1, // Ace low for A-2-3-4-5
            _ => Self::card_value(rank) // Use normal values for everything else
        }
    }

    // Check if 5 cards form a straight (handles both ace high and low)
    fn is_straight(cards: Span<Card>) -> bool {
        assert(cards.len() == 5, 'Must have 5 cards');

        // First try normal straight (ace high)
        if Self::is_normal_straight(cards) {
            return true;
        }

        // Then try wheel straight (ace low)
        Self::is_wheel_straight(cards)
    }

    // Check for normal straight (including A-K-Q-J-10)
    fn is_normal_straight(cards: Span<Card>) -> bool {
        let mut values: Array<u8> = array![];
        let mut i = 0;

        // Convert to normal card values
        while i < cards.len() {
            values.append(Self::card_value(*cards.at(i).rank));
            i += 1;
        };

        // Sort the values
        let sorted_values = sort_values(values);

        // Check if consecutive
        is_consecutive(sorted_values.span())
    }

    // Check specifically for wheel straight (A-2-3-4-5)
    fn is_wheel_straight(cards: Span<Card>) -> bool {
        let mut has_ace = false;
        let mut has_two = false;
        let mut has_three = false;
        let mut has_four = false;
        let mut has_five = false;

        let mut i = 0;
        while i < cards.len() {
            match *cards.at(i).rank {
                CardRank::Ace => has_ace = true,
                CardRank::Two => has_two = true,
                CardRank::Three => has_three = true,
                CardRank::Four => has_four = true,
                CardRank::Five => has_five = true,
                _ => {},
            }
            i += 1;
        };

        has_ace && has_two && has_three && has_four && has_five
    }

    // Get straight high card (important for comparing straights)
    fn get_straight_high_card(cards: Span<Card>) -> u8 {
        if Self::is_wheel_straight(cards) {
            return 5; // In A-2-3-4-5, the 5 is the "high" card
        }

        // For normal straights, find the highest card
        let mut highest = 0;
        let mut i = 0;
        while i < cards.len() {
            let value = Self::card_value(*cards.at(i).rank);
            if value > highest {
                highest = value;
            }
            i += 1;
        };
        highest
    }
}

fn sort_values(values: Array<u8>) -> Array<u8> {
    let mut sorted: Array<u8> = array![];
    let values_span = values.span();

    // For each position in the result array
    let mut sorted_count = 0;
    while sorted_count < values.len() {
        let mut min_value = 255_u8; // Start with max possible value
        let mut min_found = false;

        // Find the smallest value that we haven't used yet
        let mut i = 0;
        while i < values.len() {
            let current_value = *values_span.at(i);

            // Check if this value is smaller than our current minimum
            // AND we haven't already added it to our sorted array
            if current_value < min_value
                && !is_value_already_used(@sorted, current_value, sorted_count) {
                min_value = current_value;
                min_found = true;
            }
            i += 1;
        };

        // Add the minimum value we found
        if min_found {
            sorted.append(min_value);
        }
        sorted_count += 1;
    };

    sorted
}

// Helper function to check if we've already used this value
fn is_value_already_used(sorted: @Array<u8>, value: u8, count: u32) -> bool {
    let mut times_used: u8 = 0;
    let mut times_in_original = 0;

    // Count how many times this value appears in our sorted array so far
    let mut i = 0;
    while i < count {
        if *sorted.at(i) == value {
            times_used += 1;
        }
        i += 1;
    };

    times_used > 0
}


fn is_consecutive(values: Span<u8>) -> bool {
    let mut res = true;

    if values.len() != 5 {
        return false;
    }

    // Check for duplicates first
    let mut i = 0;
    while i < values.len() {
        let mut j = i + 1;
        while j < values.len() {
            if *values.at(i) == *values.at(j) {
                res = false; // Duplicates can't form straight
            }
            j += 1;
        };
        i += 1;
    };

    // Now check if consecutive
    let mut k = 1;
    while k < values.len() {
        if *values.at(k) != *values.at(k - 1) + 1 {
            res = false;
        }
        k += 1;
    };

    res
}


#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_card_from_index() {
        // Test first card (0) - Two of Spades
        let card = CardImpl::from_index(0);
        assert(card.suit == CardSuits::Spades, 'Wrong suit for index 0');
        assert(card.rank == CardRank::Two, 'Wrong rank for index 0');

        // Test Ace of Spades (12)
        let ace_spades = CardImpl::from_index(12);
        assert(ace_spades.suit == CardSuits::Spades, 'Wrong suit for Ace of Spades');
        assert(ace_spades.rank == CardRank::Ace, 'Wrong rank for Ace of Spades');

        // Test Two of Hearts (13)
        let two_hearts = CardImpl::from_index(13);
        assert(two_hearts.suit == CardSuits::Hearts, 'Wrong suit for Two of Hearts');
        assert(two_hearts.rank == CardRank::Two, 'Wrong rank for Two of Hearts');

        // Test Ace of Clubs (51 - last card)
        let ace_clubs = CardImpl::from_index(51);
        assert(ace_clubs.suit == CardSuits::Clubs, 'Wrong suit for Ace of Clubs');
        assert(ace_clubs.rank == CardRank::Ace, 'Wrong rank for Ace of Clubs');
    }

    #[test]
    fn test_card_to_index() {
        // Test Two of Spades -> 0
        let two_spades = Card { suit: CardSuits::Spades, rank: CardRank::Two };
        assert(CardImpl::to_index(two_spades) == 0, 'Wrong index for Two of Spades');

        // Test Ace of Spades -> 12
        let ace_spades = Card { suit: CardSuits::Spades, rank: CardRank::Ace };
        assert(CardImpl::to_index(ace_spades) == 12, 'Wrong index for Ace of Spades');

        // Test King of Hearts -> 24
        let king_hearts = Card { suit: CardSuits::Hearts, rank: CardRank::King };
        assert(CardImpl::to_index(king_hearts) == 24, 'Wrong index for King of Hearts');

        // Test Ace of Clubs -> 51
        let ace_clubs = Card { suit: CardSuits::Clubs, rank: CardRank::Ace };
        assert(CardImpl::to_index(ace_clubs) == 51, 'Wrong index for Ace of Clubs');
    }

    #[test]
    fn test_round_trip_conversion() {
        // Test all 52 cards can round-trip correctly
        let mut i = 0;
        while i < 52 {
            let card = CardImpl::from_index(i);
            let back_to_index = CardImpl::to_index(card);
            assert(back_to_index == i, 'Round trip failed');
            i += 1;
        };
    }

    #[test]
    fn test_card_values() {
        // Test normal card values
        assert(CardImpl::card_value(CardRank::Two) == 2, 'Two should be 2');
        assert(CardImpl::card_value(CardRank::Ten) == 10, 'Ten should be 10');
        assert(CardImpl::card_value(CardRank::Jack) == 11, 'Jack should be 11');
        assert(CardImpl::card_value(CardRank::Queen) == 12, 'Queen should be 12');
        assert(CardImpl::card_value(CardRank::King) == 13, 'King should be 13');
        assert(CardImpl::card_value(CardRank::Ace) == 14, 'Ace should be 14');

        // Test ace low values
        assert(CardImpl::card_value_ace_low(CardRank::Ace) == 1, 'Ace low should be 1');
        assert(CardImpl::card_value_ace_low(CardRank::King) == 13, 'King should still be 13');
    }

    #[test]
    fn test_face_card_detection() {
        assert(CardImpl::is_face_card(CardRank::Jack), 'Jack should be face card');
        assert(CardImpl::is_face_card(CardRank::Queen), 'Queen should be face card');
        assert(CardImpl::is_face_card(CardRank::King), 'King should be face card');
        assert(!CardImpl::is_face_card(CardRank::Ace), 'Ace should not be face card');
        assert(!CardImpl::is_face_card(CardRank::Ten), 'Ten should not be face card');
        assert(!CardImpl::is_face_card(CardRank::Two), 'Two should not be face card');
    }

    #[test]
    fn test_ace_detection() {
        assert(CardImpl::is_ace(CardRank::Ace), 'Should detect Ace');
        assert(!CardImpl::is_ace(CardRank::King), 'Should not detect King as Ace');
        assert(!CardImpl::is_ace(CardRank::Two), 'Should not detect Two as Ace');
    }

    #[test]
    fn test_normal_straight() {
        // Test 10-J-Q-K-A straight
        let broadway_straight = array![
            Card { suit: CardSuits::Spades, rank: CardRank::Ten },
            Card { suit: CardSuits::Hearts, rank: CardRank::Jack },
            Card { suit: CardSuits::Diamonds, rank: CardRank::Queen },
            Card { suit: CardSuits::Clubs, rank: CardRank::King },
            Card { suit: CardSuits::Spades, rank: CardRank::Ace },
        ];
        assert(
            CardImpl::is_normal_straight(broadway_straight.span()),
            'Should detect broadway straight',
        );

        // Test 5-6-7-8-9 straight
        let mid_straight = array![
            Card { suit: CardSuits::Spades, rank: CardRank::Five },
            Card { suit: CardSuits::Hearts, rank: CardRank::Six },
            Card { suit: CardSuits::Diamonds, rank: CardRank::Seven },
            Card { suit: CardSuits::Clubs, rank: CardRank::Eight },
            Card { suit: CardSuits::Spades, rank: CardRank::Nine },
        ];
        assert(CardImpl::is_normal_straight(mid_straight.span()), 'Should detect mid straight');
    }

    #[test]
    fn test_wheel_straight() {
        // Test A-2-3-4-5 straight (wheel)
        let wheel = array![
            Card { suit: CardSuits::Spades, rank: CardRank::Ace },
            Card { suit: CardSuits::Hearts, rank: CardRank::Two },
            Card { suit: CardSuits::Diamonds, rank: CardRank::Three },
            Card { suit: CardSuits::Clubs, rank: CardRank::Four },
            Card { suit: CardSuits::Spades, rank: CardRank::Five },
        ];
        assert(CardImpl::is_wheel_straight(wheel.span()), 'Should detect wheel straight');

        // Test that it's NOT a normal straight
        assert!(!CardImpl::is_normal_straight(wheel.span()), "Wheel should not be normal straight");

        // Test that overall is_straight works
        assert(CardImpl::is_straight(wheel.span()), 'is_straight should detect wheel');
    }

    #[test]
    fn test_non_straight() {
        // Test random cards that don't form straight
        let not_straight = array![
            Card { suit: CardSuits::Spades, rank: CardRank::Two },
            Card { suit: CardSuits::Hearts, rank: CardRank::Seven },
            Card { suit: CardSuits::Diamonds, rank: CardRank::Nine },
            Card { suit: CardSuits::Clubs, rank: CardRank::Jack },
            Card { suit: CardSuits::Spades, rank: CardRank::Ace },
        ];
        assert(!CardImpl::is_straight(not_straight.span()), 'Should not detect straight');
        assert(!CardImpl::is_normal_straight(not_straight.span()), 'Should not be normal straight');
        assert(!CardImpl::is_wheel_straight(not_straight.span()), 'Should not be wheel straight');
    }

    #[test]
    fn test_straight_high_card() {
        // Test broadway straight high card
        let broadway = array![
            Card { suit: CardSuits::Spades, rank: CardRank::Ten },
            Card { suit: CardSuits::Hearts, rank: CardRank::Jack },
            Card { suit: CardSuits::Diamonds, rank: CardRank::Queen },
            Card { suit: CardSuits::Clubs, rank: CardRank::King },
            Card { suit: CardSuits::Spades, rank: CardRank::Ace },
        ];
        assert(
            CardImpl::get_straight_high_card(broadway.span()) == 14, 'Broadway high should be Ace',
        );

        // Test wheel straight high card
        let wheel = array![
            Card { suit: CardSuits::Spades, rank: CardRank::Ace },
            Card { suit: CardSuits::Hearts, rank: CardRank::Two },
            Card { suit: CardSuits::Diamonds, rank: CardRank::Three },
            Card { suit: CardSuits::Clubs, rank: CardRank::Four },
            Card { suit: CardSuits::Spades, rank: CardRank::Five },
        ];
        assert(CardImpl::get_straight_high_card(wheel.span()) == 5, 'Wheel high should be 5');

        // Test mid straight
        let mid_straight = array![
            Card { suit: CardSuits::Spades, rank: CardRank::Six },
            Card { suit: CardSuits::Hearts, rank: CardRank::Seven },
            Card { suit: CardSuits::Diamonds, rank: CardRank::Eight },
            Card { suit: CardSuits::Clubs, rank: CardRank::Nine },
            Card { suit: CardSuits::Spades, rank: CardRank::Ten },
        ];
        assert(
            CardImpl::get_straight_high_card(mid_straight.span()) == 10,
            'Mid straight high should be 10',
        );
    }

    #[test]
    fn test_edge_cases() {
        // Test invalid indices (should panic in real usage)
        // Note: These tests would panic, so comment out for normal testing
        // let invalid_card = CardImpl::from_index(52); // Should panic
        // let invalid_card2 = CardImpl::from_index(255); // Should panic

        // Test empty arrays (your functions should handle this gracefully)
        let empty_cards: Array<Card> = array![];
        // assert(!CardImpl::is_straight(empty_cards.span()), 'Empty should not be straight');
    }

    #[test]
    fn test_all_suits_conversion() {
        // Test that all suits convert correctly
        let spades: u8 = CardSuits::Spades.into();
        assert(spades == 0, 'Spades should be 0');

        let hearts: u8 = CardSuits::Hearts.into();
        assert(hearts == 1, 'Hearts should be 1');

        let diamonds: u8 = CardSuits::Diamonds.into();
        assert(diamonds == 2, 'Diamonds should be 2');

        let clubs: u8 = CardSuits::Clubs.into();
        assert(clubs == 3, 'Clubs should be 3');

        // Test reverse conversion
        let back_to_spades: CardSuits = 0_u8.try_into().unwrap();
        assert(back_to_spades == CardSuits::Spades, 'Should convert back to Spades');

        let back_to_hearts: CardSuits = 1_u8.try_into().unwrap();
        assert(back_to_hearts == CardSuits::Hearts, 'Should convert back to Hearts');
    }

    #[test]
    fn test_all_ranks_conversion() {
        // Test a few key rank conversions
        let two: u8 = CardRank::Two.into();
        assert(two == 0, 'Two should be 0');

        let ace: u8 = CardRank::Ace.into();
        assert(ace == 12, 'Ace should be 12');

        // Test reverse conversion
        let back_to_two: CardRank = 0_u8.try_into().unwrap();
        assert(back_to_two == CardRank::Two, 'Should convert back to Two');

        let back_to_ace: CardRank = 12_u8.try_into().unwrap();
        assert(back_to_ace == CardRank::Ace, 'Should convert back to Ace');
    }
}
