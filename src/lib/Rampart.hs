-- | This module provides types and functions for defining intervals and
-- determining how they relate to each other. This can be useful to determine
-- if an event happened during a certain time frame, or if two time frames
-- overlap (and if so, how exactly they overlap).
--
-- There are many other packages on Hackage that deal with intervals, notably
-- [data-interval](https://hackage.haskell.org/package/data-interval) and
-- [intervals](https://hackage.haskell.org/package/intervals). You may prefer
-- one of them for more general interval operations. This module is more
-- focused on how intervals relate to each other.
--
-- This module was inspired by James F. Allen's report,
-- /Maintaining Knowledge About Temporal Intervals/. It also uses terminology
-- from that report. You should not need to read the report in order to
-- understand this module, but if you want to read it you can find it here:
-- <https://hdl.handle.net/1802/10574>.
module Rampart
  ( Interval
  , toInterval
  , fromInterval
  , lesser
  , greater
  , Relation(..)
  , relate
  , invert
  ) where

-- | This type represents an interval bounded by two values, the 'lesser' and
-- the 'greater'. These values can be anything with an 'Ord' instance: numbers,
-- times, strings — you name it.
--
-- Use 'toInterval' to construct an interval and 'fromInterval' to deconstruct
-- one. Use 'relate' to determine how two intervals relate to each other.
newtype Interval a = Interval (a, a)

instance Eq a => Eq (Interval a) where
  x == y = fromInterval x == fromInterval y

instance Show a => Show (Interval a) where
  show x = "toInterval " <> show (fromInterval x)

-- | Converts a tuple into an 'Interval'. Note that this requires an 'Ord'
-- constraint so that the 'Interval' can be sorted on construction.
--
-- Use 'fromInterval' to go in the other direction.
toInterval :: Ord a => (a, a) -> Interval a
toInterval (x, y) = if x > y then Interval (y, x) else Interval (x, y)

-- | Converts an 'Interval' into a tuple. Generally you can think of this as
-- the inverse of 'toInterval'. However the tuple returned by this function may
-- be swapped compared to the one originally passed to 'toInterval'.
--
-- @
-- fromInterval ('toInterval' (1, 2)) '==' (1, 2)
-- fromInterval ('toInterval' (2, 1)) '==' (1, 2)
-- @
--
-- prop> fromInterval (toInterval (x, y)) == (min x y, max x y)
fromInterval :: Interval a -> (a, a)
fromInterval (Interval x) = x

-- | Gets the lesser value from an 'Interval'.
--
-- @
-- lesser ('toInterval' (1, 2)) '==' 1
-- lesser ('toInterval' (2, 1)) '==' 1
-- @
--
-- prop> lesser (toInterval (x, y)) == min x y
lesser :: Interval a -> a
lesser = fst . fromInterval

-- | Gets the greater value from an 'Interval'.
--
-- @
-- greater ('toInterval' (1, 2)) '==' 2
-- greater ('toInterval' (2, 1)) '==' 2
-- @
--
-- prop> greater (toInterval (x, y)) == max x y
greater :: Interval a -> a
greater = snd . fromInterval

-- | This type describes how two 'Interval's relate to each other. Each
-- constructor represents one of the 13 possible relations. Taken together
-- these relations are mutually exclusive and exhaustive.
--
-- Use 'relate' to determine the relation between two 'Interval's.
data Relation
  = Before
  -- ^ 'Interval' @x@ is before 'Interval' @y@.
  --
  -- @
  -- 'greater' x '<' 'lesser' y
  -- @
  --
  -- > +---+
  -- > | x |
  -- > +---+
  -- >       +---+
  -- >       | y |
  -- >       +---+
  | Meets
  -- ^ 'Interval' @x@ meets 'Interval' @y@.
  --
  -- @
  -- 'greater' x '==' 'lesser' y
  -- @
  --
  -- > +---+
  -- > | x |
  -- > +---+
  -- >     +---+
  -- >     | y |
  -- >     +---+
  | Overlaps
  -- ^ 'Interval' @x@ overlaps 'Interval' @y@.
  --
  -- @
  -- 'lesser' x '<' 'lesser' y '&&'
  -- 'greater' x '>' 'lesser' y '&&'
  -- 'greater' x '<' 'greater' y
  -- @
  --
  -- > +---+
  -- > | x |
  -- > +---+
  -- >   +---+
  -- >   | y |
  -- >   +---+
  | FinishedBy
  -- ^ 'Interval' @x@ is finished by 'Interval' @y@.
  --
  -- @
  -- 'lesser' x '<' 'lesser' y '&&'
  -- 'greater' x '==' 'greater' y
  -- @
  --
  -- > +-----+
  -- > |  x  |
  -- > +-----+
  -- >   +---+
  -- >   | y |
  -- >   +---+
  | Contains
  -- ^ 'Interval' @x@ contains 'Interval' @y@.
  --
  -- @
  -- 'lesser' x '<' 'lesser' y '&&'
  -- 'greater' x '>' 'greater' y
  -- @
  --
  -- > +-------+
  -- > |   x   |
  -- > +-------+
  -- >   +---+
  -- >   | y |
  -- >   +---+
  | Starts
  -- ^ 'Interval' @x@ starts 'Interval' @y@.
  --
  -- @
  -- 'lesser' x '==' 'lesser' y '&&'
  -- 'greater' x '<' 'greater' y
  -- @
  --
  -- > +---+
  -- > | x |
  -- > +---+
  -- > +-----+
  -- > |  y  |
  -- > +-----+
  | Equal
  -- ^ 'Interval' @x@ is equal to 'Interval' @y@.
  --
  -- @
  -- 'lesser' x '==' 'lesser' y '&&'
  -- 'greater' x '==' 'greater' y
  -- @
  --
  -- > +---+
  -- > | x |
  -- > +---+
  -- > +---+
  -- > | y |
  -- > +---+
  | StartedBy
  -- ^ 'Interval' @x@ is started by 'Interval' @y@.
  --
  -- @
  -- 'lesser' x '==' 'lesser' y '&&'
  -- 'greater' x '>' 'greater' y
  -- @
  --
  -- > +-----+
  -- > |  x  |
  -- > +-----+
  -- > +---+
  -- > | y |
  -- > +---+
  | During
  -- ^ 'Interval' @x@ is during 'Interval' @y@.
  --
  -- @
  -- 'lesser' x '>' 'lesser' y '&&'
  -- 'greater' x '<' 'greater' y
  -- @
  --
  -- >   +---+
  -- >   | x |
  -- >   +---+
  -- > +-------+
  -- > |   y   |
  -- > +-------+
  | Finishes
  -- ^ 'Interval' @x@ finishes 'Interval' @y@.
  --
  -- @
  -- 'lesser' x '>' 'lesser' y '&&'
  -- 'greater' x '==' 'greater' y
  -- @
  --
  -- >   +---+
  -- >   | x |
  -- >   +---+
  -- > +-----+
  -- > |  y  |
  -- > +-----+
  | OverlappedBy
  -- ^ 'Interval' @x@ is overlapped by 'Interval' @y@.
  --
  -- @
  -- 'lesser' x '>' 'lesser' y '&&'
  -- 'lesser' x '<' 'greater' y '&&'
  -- 'greater' x '>' 'greater' y
  -- @
  --
  -- >   +---+
  -- >   | x |
  -- >   +---+
  -- > +---+
  -- > | y |
  -- > +---+
  | MetBy
  -- ^ 'Interval' @x@ is met by 'Interval' @y@.
  --
  -- @
  -- 'lesser' x '==' 'greater' y
  -- @
  --
  -- >     +---+
  -- >     | x |
  -- >     +---+
  -- > +---+
  -- > | y |
  -- > +---+
  | After
  -- ^ 'Interval' @x@ is after 'Interval' @y@.
  --
  -- @
  -- 'lesser' x '>' 'greater' y
  -- @
  --
  -- >       +---+
  -- >       | x |
  -- >       +---+
  -- > +---+
  -- > | y |
  -- > +---+

instance Eq Relation where
  x == y = case (x, y) of
    (After, After) -> True
    (Before, Before) -> True
    (Contains, Contains) -> True
    (During, During) -> True
    (Equal, Equal) -> True
    (FinishedBy, FinishedBy) -> True
    (Finishes, Finishes) -> True
    (Meets, Meets) -> True
    (MetBy, MetBy) -> True
    (OverlappedBy, OverlappedBy) -> True
    (Overlaps, Overlaps) -> True
    (StartedBy, StartedBy) -> True
    (Starts, Starts) -> True
    _ -> False

instance Show Relation where
  show x = case x of
    After -> "After"
    Before -> "Before"
    Contains -> "Contains"
    During -> "During"
    Equal -> "Equal"
    FinishedBy -> "FinishedBy"
    Finishes -> "Finishes"
    Meets -> "Meets"
    MetBy -> "MetBy"
    OverlappedBy -> "OverlappedBy"
    Overlaps -> "Overlaps"
    StartedBy -> "StartedBy"
    Starts -> "Starts"

-- | Relates two 'Interval's. Calling @relate x y@ tells you how 'Interval' @x@
-- relates to 'Interval' @y@. Consult the 'Relation' documentation for an
-- explanation of all the possible results.
--
-- @
-- relate ('toInterval' (1, 2)) ('toInterval' (3, 7)) '==' 'Before'
-- relate ('toInterval' (2, 3)) ('toInterval' (3, 7)) '==' 'Meets'
-- relate ('toInterval' (2, 4)) ('toInterval' (3, 7)) '==' 'Overlaps'
-- relate ('toInterval' (2, 7)) ('toInterval' (3, 7)) '==' 'FinishedBy'
-- relate ('toInterval' (2, 8)) ('toInterval' (3, 7)) '==' 'Contains'
-- relate ('toInterval' (3, 4)) ('toInterval' (3, 7)) '==' 'Starts'
-- relate ('toInterval' (3, 7)) ('toInterval' (3, 7)) '==' 'Equal'
-- relate ('toInterval' (3, 8)) ('toInterval' (3, 7)) '==' 'StartedBy'
-- relate ('toInterval' (4, 6)) ('toInterval' (3, 7)) '==' 'During'
-- relate ('toInterval' (6, 7)) ('toInterval' (3, 7)) '==' 'Finishes'
-- relate ('toInterval' (6, 8)) ('toInterval' (3, 7)) '==' 'OverlappedBy'
-- relate ('toInterval' (7, 8)) ('toInterval' (3, 7)) '==' 'MetBy'
-- relate ('toInterval' (8, 9)) ('toInterval' (3, 7)) '==' 'After'
-- @
relate :: Ord a => Interval a -> Interval a -> Relation
relate x y =
  let
    lxly = compare (lesser x) (lesser y)
    lxgy = compare (lesser x) (greater y)
    gxly = compare (greater x) (lesser y)
    gxgy = compare (greater x) (greater y)
  in case (lxly, lxgy, gxly, gxgy) of
    (_, _, LT, _) -> Before
    (_, _, EQ, _) -> Meets
    (_, EQ, _, _) -> MetBy
    (_, GT, _, _) -> After
    (LT, _, _, LT) -> Overlaps
    (LT, _, _, EQ) -> FinishedBy
    (LT, _, _, GT) -> Contains
    (EQ, _, _, LT) -> Starts
    (EQ, _, _, EQ) -> Equal
    (EQ, _, _, GT) -> StartedBy
    (GT, _, _, LT) -> During
    (GT, _, _, EQ) -> Finishes
    (GT, _, _, GT) -> OverlappedBy

-- | Inverts a 'Relation'. Every 'Relation' has an inverse.
--
-- @
-- invert 'Before'       '==' 'After'
-- invert 'After'        '==' 'Before'
-- invert 'Meets'        '==' 'MetBy'
-- invert 'MetBy'        '==' 'Meets'
-- invert 'Overlaps'     '==' 'OverlappedBy'
-- invert 'OverlappedBy' '==' 'Overlaps'
-- invert 'Starts'       '==' 'StartedBy'
-- invert 'StartedBy'    '==' 'Starts'
-- invert 'Finishes'     '==' 'FinishedBy'
-- invert 'FinishedBy'   '==' 'Finishes'
-- invert 'Contains'     '==' 'During'
-- invert 'During'       '==' 'Contains'
-- invert 'Equal'        '==' 'Equal'
-- @
--
-- Inverting a 'Relation' twice will return the original 'Relation'.
--
-- prop> invert (invert r) == r
--
-- Inverting a 'Relation' is like swapping the arguments to 'relate'.
--
-- prop> invert (relate x y) == relate y x
invert :: Relation -> Relation
invert x = case x of
  After -> Before
  Before -> After
  Contains -> During
  During -> Contains
  Equal -> Equal
  FinishedBy -> Finishes
  Finishes -> FinishedBy
  Meets -> MetBy
  MetBy -> Meets
  OverlappedBy -> Overlaps
  Overlaps -> OverlappedBy
  StartedBy -> Starts
  Starts -> StartedBy
