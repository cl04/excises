{-# LANGUAGE FlexibleContexts #-}
import Text.Parsec
import Control.Monad.State

integer :: Monad m => ParsecT String s m Int
integer = read <$> many1 digit

getNext k x  | x >  n2 = n1 * base + x
             | x <= n2 = (1 + n1) * base + x
    where    base = 10 ^ countDigits x
             (n1, n2) = k `quotRem` base
             countDigits = length . show

dashed :: MonadState Int m => ParsecT String s m [Int]
dashed = do
  from <- liftM2 getNext get integer
  char '-'
  to <- integer
  let next = getNext from to
  put next
  return $! [from .. next]

coloned2 :: MonadState Int m => ParsecT String s m [Int]
coloned2 = do
  from <- liftM2 getNext get integer
  char ':'
  to <- integer
  char ':'
  step <- integer
  let next = getNext from to
  put next
  return $! [from, from + step .. next]

coloned1 :: MonadState Int m => ParsecT String s m [Int]
coloned1 = do
  from <- liftM2 getNext get integer
  char ','
  to <- integer
  char ':'
  step <- integer
  let from' = getNext from to
      next  = getNext from' step
  put next
  return $! from : [from'..next]

dotted :: MonadState Int m => ParsecT String s m [Int]
dotted = do
  from <- liftM2 getNext get integer
  string ".."
  to <- integer
  let next = getNext from to
  put next
  return [from .. next]
  
intP :: MonadState Int m => ParsecT String s m [Int]
intP = do
  next <- liftM2 getNext get integer
  put next
  return [next]

rangedP :: MonadState Int m => ParsecT String s m [Int]
rangedP = try coloned1
      <|> try coloned2
      <|> try dashed
      <|> try dotted
      <|> intP

parser :: MonadState Int m => ParsecT String s m [Int]
parser = concat <$> sepBy rangedP (char ',')

parseRangedInts :: String -> Either ParseError [Int]
parseRangedInts s = evalState (runParserT parser 0 "<stdin>" s) (-1)
