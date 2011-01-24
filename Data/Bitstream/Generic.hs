{-# LANGUAGE
    RankNTypes
  , UnicodeSyntax
  #-}
module Data.Bitstream.Generic
    ( Bitstream(..)

    , (∅)
    , (⧺)
    , (∈)
    , (∋)
    , (∉)
    , (∌)
    , (∖)
    , (∪)
    , (∩)
    , (∆)
    )
    where
import qualified Data.List.Stream as L
import Data.Maybe
import qualified Data.Stream as S
import Prelude ( Bool(..), Integer, Integral(..), Num(..), Ord(..), flip
               , otherwise
               )
import Prelude.Unicode hiding ((∈), (∉), (⧺))

infix  4 ∈, ∋, ∉, ∌, `elem`, `notElem`
infixr 5 ⧺, `append`
infixl 6 ∪, `union`
infixr 6 ∩, `intersect`
infixl 9 !!, ∖, \\, ∆

-- THINKME: consider using numeric-prelude's non-negative numbers
-- instead of Integral n.

snocL ∷ [α] → α → [α]
snocL xs x = xs L.++ [x]
{-# INLINE snocL #-}

class Bitstream α where
    pack   ∷ [Bool] → α
    unpack ∷ α → [Bool]

    stream ∷ α → S.Stream Bool
    stream = S.stream ∘ unpack
    {-# INLINE stream #-}

    unstream ∷ S.Stream Bool → α
    unstream = pack ∘ S.unstream
    {-# INLINE unstream #-}

    empty ∷ α
    empty = pack []
    {-# INLINE empty #-}

    singleton ∷ Bool → α
    singleton = pack ∘ flip (:) []
    {-# INLINE singleton #-}

    cons ∷ Bool → α → α
    cons = (pack ∘) ∘ (∘ unpack) ∘ (:)
    {-# INLINE cons #-}

    snoc ∷ α → Bool → α
    snoc α a = pack (unpack α `snocL` a)
    {-# INLINE snoc #-}

    append ∷ α → α → α
    append = (pack ∘) ∘ (∘ unpack) ∘ (L.++) ∘ unpack
    {-# INLINE append #-}

    head ∷ α → Bool
    head = L.head ∘ unpack
    {-# INLINE head #-}

    uncons ∷ α → Maybe (Bool, α)
    uncons α
        | null α    = Nothing
        | otherwise = Just (head α, tail α)
    {-# INLINE uncons #-}

    last ∷ α → Bool
    last = L.last ∘ unpack
    {-# INLINE last #-}

    tail ∷ α → α
    tail = pack ∘ L.tail ∘ unpack
    {-# INLINE tail #-}

    init ∷ α → α
    init = pack ∘ L.init ∘ unpack
    {-# INLINE init #-}

    null ∷ α → Bool
    null = L.null ∘ unpack
    {-# INLINE null #-}

    length ∷ Num n ⇒ α → n
    length = L.genericLength ∘ unpack
    {-# INLINE length #-}

    map ∷ (Bool → Bool) → α → α
    map = (pack ∘) ∘ (∘ unpack) ∘ L.map
    {-# INLINE map #-}

    reverse ∷ α → α
    reverse = foldl' (flip cons) (∅)
    {-# INLINE reverse #-}

    intersperse ∷ Bool → α → α
    intersperse = (pack ∘) ∘ (∘ unpack) ∘ L.intersperse
    {-# INLINE intersperse #-}

    intercalate ∷ α → [α] → α
    intercalate α αs = pack (L.intercalate (unpack α) (L.map unpack αs))
    {-# INLINE intercalate #-}

    transpose ∷ [α] → [α]
    transpose []     = []
    transpose (α:αs)
        = case uncons α of
            Nothing      → transpose αs
            Just (a, as) → (a `cons` pack (L.map head αs))
                           : transpose (as : L.map tail αs)
    {-# INLINEABLE transpose #-}

    foldl ∷ (β → Bool → β) → β → α → β
    foldl f β = L.foldl f β ∘ unpack
    {-# INLINE foldl #-}

    foldl' ∷ (β → Bool → β) → β → α → β
    foldl' f β = L.foldl' f β ∘ unpack
    {-# INLINE foldl' #-}

    foldl1 ∷ (Bool → Bool → Bool) → α → Bool
    foldl1 = (∘ unpack) ∘ L.foldl1
    {-# INLINE foldl1 #-}

    foldl1' ∷ (Bool → Bool → Bool) → α → Bool
    foldl1' = (∘ unpack) ∘ L.foldl1'
    {-# INLINE foldl1' #-}

    foldr ∷ (Bool → β → β) → β → α → β
    foldr f β = L.foldr f β ∘ unpack
    {-# INLINE foldr #-}

    foldr1 ∷ (Bool → Bool → Bool) → α → Bool
    foldr1 = (∘ unpack) ∘ L.foldr1
    {-# INLINE foldr1 #-}

    concat ∷ [α] → α
    concat = pack ∘ L.concatMap unpack
    {-# INLINE concat #-}

    concatMap ∷ (Bool → α) → α → α
    concatMap f = pack ∘ L.concatMap (unpack ∘ f) ∘ unpack
    {-# INLINE concatMap #-}

    and ∷ α → Bool
    and = L.and ∘ unpack
    {-# INLINE and #-}

    or ∷ α → Bool
    or = L.or ∘ unpack
    {-# INLINE or #-}

    any ∷ (Bool → Bool) → α → Bool
    any = (∘ unpack) ∘ L.any
    {-# INLINE any #-}

    all ∷ (Bool → Bool) → α → Bool
    all = (∘ unpack) ∘ L.all
    {-# INLINE all #-}

    scanl ∷ (Bool → Bool → Bool) → Bool → α → α
    scanl f β α = pack (L.scanl f β (snocL (unpack α) (⊥)))
    {-# INLINE scanl #-}

    scanl1 ∷ (Bool → Bool → Bool) → α → α
    scanl1 f α = pack (L.scanl1 f (snocL (unpack α) (⊥)))
    {-# INLINE scanl1 #-}

    scanr ∷ (Bool → Bool → Bool) → Bool → α → α
    scanr f β α
        = case uncons α of
            Nothing      → singleton β
            Just (a, as) → let α' = scanr f β as
                           in
                             f a (head α') `cons` α'
    {-# INLINEABLE scanr #-}

    scanr1 ∷ (Bool → Bool → Bool) → α → α
    scanr1 f α
        = case uncons α of
            Nothing         → α
            Just (a, as)
                | null as   → α
                | otherwise → let α' = scanr1 f as
                              in
                                f a (head α') `cons` α'
    {-# INLINEABLE scanr1 #-}

    mapAccumL ∷ (β → Bool → (β, Bool)) → β → α → (β, α)
    mapAccumL f s α
        = case uncons α of
            Nothing      → (s, α)
            Just (a, as) → let (s' , b ) = f s a
                               (s'', α') = mapAccumL f s' as
                           in
                             (s'', b `cons` α')
    {-# INLINEABLE mapAccumL #-}

    mapAccumR ∷ (β → Bool → (β, Bool)) → β → α → (β, α)
    mapAccumR f s α
        = case uncons α of
            Nothing      → (s, α)
            Just (a, as) → let (s'', b ) = f s' a
                               (s' , α') = mapAccumR f s as
                           in
                             (s'', b `cons` α')
    {-# INLINEABLE mapAccumR #-}

    replicate ∷ Integral n ⇒ n → Bool → α
    replicate n b
        | n ≤ 0     = (∅)
        | otherwise = b `cons` replicate (n-1) b
    {-# INLINEABLE replicate #-}

-- FIXME: Provide these only for lazy streams!
{-
    iterate ∷ (Bool → Bool) → Bool → α
    iterate = (pack ∘) ∘ L.iterate
    {-# INLINE iterate #-}

    repeat ∷ Bool → α
    repeat = pack ∘ L.repeat
    {-# INLINE repeat #-}

    cycle ∷ α → α
    cycle = pack ∘ L.cycle ∘ unpack
    {-# INLINE cycle #-}
-}

    unfoldr ∷ (β → Maybe (Bool, β)) → β → α
    unfoldr = (pack ∘) ∘ L.unfoldr
    {-# INLINE unfoldr #-}

    unfoldrN ∷ Integral n ⇒ n → (β → Maybe (Bool, β)) → β → (α, Maybe β)
    unfoldrN n0 f β0
        | n0 < 0    = ((∅), Just β0)
        | otherwise = loop_unfoldrN n0 β0 (∅)
        where
          loop_unfoldrN 0 β α = (α, Just β)
          loop_unfoldrN n β α
              = case f β of
                  Nothing      → (α, Nothing)
                  Just (a, β') → loop_unfoldrN (n-1) β' (α `snoc` a)
    {-# INLINE unfoldrN #-}

    take ∷ Integral n ⇒ n → α → α
    take = (pack ∘) ∘ (∘ unpack) ∘ L.genericTake
    {-# INLINE take #-}

    drop ∷ Integral n ⇒ n → α → α
    drop = (pack ∘) ∘ (∘ unpack) ∘ L.genericDrop
    {-# INLINE drop #-}

    splitAt ∷ Integral n ⇒ n → α → (α, α)
    splitAt n α
        = (take n α, drop n α)
    {-# INLINE splitAt #-}

    takeWhile ∷ (Bool → Bool) → α → α
    takeWhile = (pack ∘) ∘ (∘ unpack) ∘ L.takeWhile
    {-# INLINE takeWhile #-}

    dropWhile ∷ (Bool → Bool) → α → α
    dropWhile = (pack ∘) ∘ (∘ unpack) ∘ L.dropWhile
    {-# INLINE dropWhile #-}

    span ∷ (Bool → Bool) → α → (α, α)
    span f α
        = let hd = takeWhile f α
              tl = drop (length hd ∷ Integer) α
          in
            (hd, tl)
    {-# INLINEABLE span #-}

    break ∷ (Bool → Bool) → α → (α, α)
    break f = span ((¬) ∘ f)
    {-# INLINE break #-}

    group ∷ α → [α]
    group α
        = case uncons α of
            Nothing      → []
            Just (a, as) → let (β, γ) = span (a ≡) as
                           in
                             (a `cons` β) : group γ
    {-# INLINEABLE group #-}

    inits ∷ α → [α]
    inits α
        = case uncons α of
            Nothing      → α : []
            Just (a, as) → (∅) : L.map (cons a) (inits as)
    {-# INLINEABLE inits #-}

    tails ∷ α → [α]
    tails α
        = case uncons α of
            Nothing      → α : []
            Just (_, as) → α : tails as
    {-# INLINEABLE tails #-}

    isPrefixOf ∷ α → α → Bool
    isPrefixOf x y = L.isPrefixOf (unpack x) (unpack y)
    {-# INLINE isPrefixOf #-}

    isSuffixOf ∷ α → α → Bool
    isSuffixOf x y = reverse x `isPrefixOf` reverse y
    {-# INLINE isSuffixOf #-}

    isInfixOf ∷ α → α → Bool
    isInfixOf x y = L.any (x `isPrefixOf`) (tails y)
    {-# INLINE isInfixOf #-}

    elem ∷ Bool → α → Bool
    elem True  = or
    elem False = (¬) ∘ and
    {-# INLINE elem #-}

    notElem ∷ Bool → α → Bool
    notElem = ((¬) ∘) ∘ (∈)
    {-# INLINE notElem #-}

    find ∷ (Bool → Bool) → α → Maybe Bool
    find = (∘ unpack) ∘ L.find
    {-# INLINE find #-}

    filter ∷ (Bool → Bool) → α → α
    filter = (pack ∘) ∘ (∘ unpack) ∘ L.filter
    {-# INLINE filter #-}

    partition ∷ (Bool → Bool) → α → (α, α)
    partition f α = (filter f α, filter ((¬) ∘ f) α)
    {-# INLINEABLE partition #-}

    (!!) ∷ Integral n ⇒ α → n → Bool
    (!!) = L.genericIndex ∘ unpack
    {-# INLINE (!!) #-}

    elemIndex ∷ Integral n ⇒ Bool → α → Maybe n
    elemIndex = findIndex ∘ (≡)
    {-# INLINE elemIndex #-}

    elemIndices ∷ Integral n ⇒ Bool → α → [n]
    elemIndices = findIndices ∘ (≡)
    {-# INLINE elemIndices #-}

    findIndex ∷ Integral n ⇒ (Bool → Bool) → α → Maybe n
    findIndex = (listToMaybe ∘) ∘ findIndices
    {-# INLINE findIndex #-}

    findIndices ∷ Integral n ⇒ (Bool → Bool) → α → [n]
    findIndices f = find' 0
        where
          find' n α
              = case uncons α of
                  Nothing         → []
                  Just (a, as)
                      | f a       → n : find' (n+1) as
                      | otherwise →     find' (n+1) as
    {-# INLINEABLE findIndices #-}

    zip ∷ α → α → [(Bool, Bool)]
    zip a b = L.zip (unpack a) (unpack b)
    {-# INLINE zip #-}

    zip3 ∷ α → α → α → [(Bool, Bool, Bool)]
    zip3 = zipWith3 (,,)
    {-# INLINE zip3 #-}

    zip4 ∷ α → α → α → α → [(Bool, Bool, Bool, Bool)]
    zip4 = zipWith4 (,,,)
    {-# INLINE zip4 #-}

    zip5 ∷ α → α → α → α → α → [(Bool, Bool, Bool, Bool, Bool)]
    zip5 = zipWith5 (,,,,)
    {-# INLINE zip5 #-}

    zip6 ∷ α → α → α → α → α → α → [(Bool, Bool, Bool, Bool, Bool, Bool)]
    zip6 = zipWith6 (,,,,,)
    {-# INLINE zip6 #-}

    zip7 ∷ α → α → α → α → α → α → α → [(Bool, Bool, Bool, Bool, Bool, Bool, Bool)]
    zip7 = zipWith7 (,,,,,,)
    {-# INLINE zip7 #-}

    zipWith ∷ (Bool → Bool → β) → α → α → [β]
    zipWith f α β = L.zipWith f
                      (unpack α)
                      (unpack β)
    {-# INLINE zipWith #-}

    zipWith3 ∷ (Bool → Bool → Bool → β) → α → α → α → [β]
    zipWith3 f α β γ = L.zipWith3 f
                          (unpack α)
                          (unpack β)
                          (unpack γ)
    {-# INLINE zipWith3 #-}

    zipWith4 ∷ (Bool → Bool → Bool → Bool → β) → α → α → α → α → [β]
    zipWith4 f α β γ δ = L.zipWith4 f
                             (unpack α)
                             (unpack β)
                             (unpack γ)
                             (unpack δ)
    {-# INLINE zipWith4 #-}

    zipWith5 ∷ (Bool → Bool → Bool → Bool → Bool → β) → α → α → α → α → α → [β]
    zipWith5 f α β γ δ ε = L.zipWith5 f
                                (unpack α)
                                (unpack β)
                                (unpack γ)
                                (unpack δ)
                                (unpack ε)
    {-# INLINE zipWith5 #-}

    zipWith6 ∷ (Bool → Bool → Bool → Bool → Bool → Bool → β) → α → α → α → α → α → α → [β]
    zipWith6 f α β γ δ ε ζ = L.zipWith6 f
                                   (unpack α)
                                   (unpack β)
                                   (unpack γ)
                                   (unpack δ)
                                   (unpack ε)
                                   (unpack ζ)
    {-# INLINE zipWith6 #-}

    zipWith7 ∷ (Bool → Bool → Bool → Bool → Bool → Bool → Bool → β) → α → α → α → α → α → α → α → [β]
    zipWith7 f α β γ δ ε ζ η = L.zipWith7 f
                                      (unpack α)
                                      (unpack β)
                                      (unpack γ)
                                      (unpack δ)
                                      (unpack ε)
                                      (unpack ζ)
                                      (unpack η)
    {-# INLINE zipWith7 #-}

    unzip ∷ [(Bool, Bool)] → (α, α)
    unzip = L.foldr (\(a, b) ~(as, bs) →
                         ( a `cons` as
                         , b `cons` bs )) ((∅), (∅))
    {-# INLINEABLE unzip #-}

    unzip3 ∷ [(Bool, Bool, Bool)] → (α, α, α)
    unzip3 = L.foldr (\(a, b, c) ~(as, bs, cs) →
                          ( a `cons` as
                          , b `cons` bs
                          , c `cons` cs )) ((∅), (∅), (∅))
    {-# INLINEABLE unzip3 #-}

    unzip4 ∷ [(Bool, Bool, Bool, Bool)] → (α, α, α, α)
    unzip4 = L.foldr (\(a, b, c, d) ~(as, bs, cs, ds) →
                          ( a `cons` as
                          , b `cons` bs
                          , c `cons` cs
                          , d `cons` ds )) ((∅), (∅), (∅), (∅))
    {-# INLINEABLE unzip4 #-}

    unzip5 ∷ [(Bool, Bool, Bool, Bool, Bool)] → (α, α, α, α, α)
    unzip5 = L.foldr (\(a, b, c, d, e) ~(as, bs, cs, ds, es) →
                          ( a `cons` as
                          , b `cons` bs
                          , c `cons` cs
                          , d `cons` ds
                          , e `cons` es )) ((∅), (∅), (∅), (∅), (∅))
    {-# INLINEABLE unzip5 #-}

    unzip6 ∷ [(Bool, Bool, Bool, Bool, Bool, Bool)] → (α, α, α, α, α, α)
    unzip6 = L.foldr (\(a, b, c, d, e, f) ~(as, bs, cs, ds, es, fs) →
                          ( a `cons` as
                          , b `cons` bs
                          , c `cons` cs
                          , d `cons` ds
                          , e `cons` es
                          , f `cons` fs )) ((∅), (∅), (∅), (∅), (∅), (∅))
    {-# INLINEABLE unzip6 #-}

    unzip7 ∷ [(Bool, Bool, Bool, Bool, Bool, Bool, Bool)] → (α, α, α, α, α, α, α)
    unzip7 = L.foldr (\(a, b, c, d, e, f, g) ~(as, bs, cs, ds, es, fs, gs) →
                          ( a `cons` as
                          , b `cons` bs
                          , c `cons` cs
                          , d `cons` ds
                          , e `cons` es
                          , f `cons` fs
                          , g `cons` gs )) ((∅), (∅), (∅), (∅), (∅), (∅), (∅))
    {-# INLINEABLE unzip7 #-}

    nub ∷ α → α
    nub = flip nub' (∅)
        where
          nub' ∷ Bitstream α ⇒ α → α → α
          nub' α α'
              = case uncons α of
                  Nothing         → α
                  Just (a, as)
                      | a ∈ α'    → nub' as α'
                      | otherwise → a `cons` nub' as (a `cons` α')
    {-# INLINEABLE nub #-}

    delete ∷ Bool → α → α
    delete = deleteBy (≡)
    {-# INLINE delete #-}

    (\\) ∷ α → α → α
    (\\) = foldl (flip delete)
    {-# INLINE (\\) #-}

    union ∷ α → α → α
    union = unionBy (≡)
    {-# INLINE union #-}

    intersect ∷ α → α → α
    intersect = intersectBy (≡)
    {-# INLINE intersect #-}

    nubBy ∷ (Bool → Bool → Bool) → α → α
    nubBy f = flip nubBy' (∅)
        where
          nubBy' ∷ Bitstream α ⇒ α → α → α
          nubBy' α α'
              = case uncons α of
                  Nothing            → α
                  Just (a, as)
                      | elemBy' a α' → nubBy' as α'
                      | otherwise    → a `cons` nubBy' as (a `cons` α')

          elemBy' ∷ Bitstream α ⇒ Bool → α → Bool
          elemBy' b α
              = case uncons α of
                  Nothing         → False
                  Just (a, as)
                      | f b a     → True
                      | otherwise → elemBy' b as
    {-# INLINEABLE nubBy #-}

    deleteBy ∷ (Bool → Bool → Bool) → Bool → α → α
    deleteBy f b α
        = case uncons α of
            Nothing         → α
            Just (a, as)
                | f b a     → as
                | otherwise → a `cons` deleteBy f b as
    {-# INLINEABLE deleteBy #-}

    deleteFirstsBy ∷ (Bool → Bool → Bool) → α → α → α
    deleteFirstsBy = foldl ∘ flip ∘ deleteBy
    {-# INLINEABLE deleteFirstsBy #-}

    unionBy ∷ (Bool → Bool → Bool) → α → α → α
    unionBy f x y = x ⧺ foldl (flip (deleteBy f)) (nubBy f y) x
    {-# INLINEABLE unionBy #-}

    intersectBy ∷ (Bool → Bool → Bool) → α → α → α
    intersectBy f x y = filter (\a → any (f a) y) x
    {-# INLINEABLE intersectBy #-}

    groupBy ∷ (Bool → Bool → Bool) → α → [α]
    groupBy f α
        = case uncons α of
            Nothing     → []
            Just (a, _) → let (β, γ) = span (f a) α
                          in
                            (a `cons` β) : groupBy f γ
    {-# INLINEABLE groupBy #-}

(∅) ∷ Bitstream α ⇒ α
(∅) = empty
{-# INLINE (∅) #-}

(⧺) ∷ Bitstream α ⇒ α → α → α
(⧺) = append
{-# INLINE (⧺) #-}

(∈) ∷ Bitstream α ⇒ Bool → α → Bool
(∈) = elem
{-# INLINE (∈) #-}

(∋) ∷ Bitstream α ⇒ α → Bool → Bool
(∋) = flip elem
{-# INLINE (∋) #-}

(∉) ∷ Bitstream α ⇒ Bool → α → Bool
(∉) = notElem
{-# INLINE (∉) #-}

(∌) ∷ Bitstream α ⇒ α → Bool → Bool
(∌) = flip notElem
{-# INLINE (∌) #-}

(∖) ∷ Bitstream α ⇒ α → α → α
(∖) = (\\)
{-# INLINE (∖) #-}

(∪) ∷ Bitstream α ⇒ α → α → α
(∪) = union
{-# INLINE (∪) #-}

(∩) ∷ Bitstream α ⇒ α → α → α
(∩) = intersect
{-# INLINE (∩) #-}

(∆) ∷ Bitstream α ⇒ α → α → α
x ∆ y = (x ∖ y) ∪ (y ∖ x)
{-# INLINE (∆) #-}

{-# RULES

"Bitstream unpack/pack fusion"
    ∀l. unpack (pack l) = l

"Bitstream stream/unstream fusion"
    ∀s. stream (unstream s) = s

"Bitstream stream / List unstream fusion"
    ∀s. stream (S.unstream s) = s

"List stream / Bitstream unstream fusion"
    ∀s. S.stream (unstream s) = s

  #-}