-----------------------------------------------------------------------------
-- |
-- Module      :  W.hs
-- Copyright   :  (c) Spencer Janssen 2007
-- License     :  BSD3-style (see LICENSE)
-- 
-- Maintainer  :  sjanssen@cse.unl.edu
-- Stability   :  unstable
-- Portability :  not portable, uses cunning newtype deriving
--
-----------------------------------------------------------------------------
--
-- The W monad, a state monad transformer over IO, for the window
-- manager state, and support routines.
--

module W where

import System.IO
import Graphics.X11.Xlib
import Control.Monad.State

-- | WState, the window manager state.
-- Just the display, width, height and a window list
data WState = WState
    { display       :: Display
    , screenWidth   :: !Int
    , screenHeight  :: !Int
    , windows       :: !Windows
    }

type Windows = [Window]

-- | The W monad, a StateT transformer over IO encapuslating the window
-- manager state
newtype W a = W { unW :: StateT WState IO a }
    deriving (Functor, Monad, MonadIO)

-- | Run the W monad, given a chunk of W monad code, and an initial state
-- Return the result, and final state
runW :: WState -> W a -> IO (a, WState)
runW st a = runStateT (unW a) st

-- | Lift an IO action into the W monad
io :: IO a -> W a
io = liftIO

-- | Lift an IO action into the W monad, discarding any result
io_ :: IO a -> W ()
io_ f = liftIO f >> return ()

-- | A 'trace' for the W monad. Logs a string to stderr. The result may
-- be found in your .xsession-errors file
trace :: String -> W ()
trace msg = io $ do
    hPutStrLn stderr msg
    hFlush stderr

-- ---------------------------------------------------------------------
-- Getting at the window manager state

-- | Return the current dispaly
getDisplay          :: W Display
getDisplay          = W (gets display)

-- | Return the current windows
getWindows          :: W Windows
getWindows          = W (gets windows)

-- | Return the screen width
getScreenWidth      :: W Int
getScreenWidth      = W (gets screenWidth)

-- | Return the screen height
getScreenHeight     :: W Int
getScreenHeight     = W (gets screenHeight)

-- | Set the current window list
setWindows          ::Windows -> W ()
setWindows x        = W (modify (\s -> s {windows = x}))

-- | Modify the current window list
modifyWindows       :: (Windows -> Windows) -> W ()
modifyWindows f     = W (modify (\s -> s {windows = f (windows s)}))

-- ---------------------------------------------------------------------
-- Generic utilities

-- | Run an action forever
forever :: (Monad m) => m a -> m b
forever a = a >> forever a

-- | Add an element onto the end of a list
snoc :: [a] -> a -> [a]
snoc xs x = xs ++ [x]

-- | Rotate a list one element
rotate []     = []
rotate (x:xs) = xs `snoc` x