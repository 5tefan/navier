> module Navier.Output where

> import Data.Bits
> import Data.Char
> import Data.Array.Repa
> import Data.Array.Parallel.Base ((:*:)(..))

> import System.Directory
> import System.IO
> import Text.Printf

> import Navier.Datadefs
> import Navier.Params

> calc_zeta :: Array DIM2 Double -> Array DIM2 Double -> 
>                  Array DIM2 Int -> Int -> Int -> Double -> Double
>                  -> Array DIM2 Double
> calc_zeta (uA@Manifest{}) (vA@Manifest{}) (flagA@Manifest{}) imax jmax delx dely = 
>       force $ traverse (Data.Array.Repa.zipWith (:*:) flagA
>          (Data.Array.Repa.zipWith (:*:) uA vA)) id calcZeta
>            where
>              flag = fsta
>              u = fsta . snda
>              v = snda . snda
>              calcZeta get c@(sh :. j :. i) = 
>                    if (inBounds i j && (i<=(imax-1)) && (j<=(jmax-1))) then
>                        if (((flag $ get c) .&. _cf /= 0) &&
>                            ((flag $ get (sh :. j :. (i+1))) .&. _cf /= 0) &&
>                            ((flag $ get (sh :. (j+1) :. i)) .&. _cf /= 0) &&
>                            ((flag $ get (sh :. (j+1) :. (i+1))) .&. _cf /= 0)) then
>                                   ((u $ get (sh :. (j+1) :. i)) - (u $ get c))/dely
>                                 - ((v $ get (sh :. j :. (i+1))) - (v $ get c))/delx
>                        else
>                            0.0
>                    else
>                        0.0

> write_ppm :: Array DIM2 Double -> Array DIM2 Double -> Array DIM2 Double
>              -> Array DIM2 Int -> Int -> Int -> Double -> Double -> String
>              -> Int -> Int -> IO ()
> write_ppm (u@Manifest{}) (v@Manifest{}) (p@Manifest{}) (flag@Manifest{})
>              imax jmax delx dely outname iters freq =
>     do createDirectoryIfMissing True outname
>        let filename = printf "%s/%06d.ppm" outname (iters `div` freq)
>        file <- openBinaryFile filename WriteMode
>        let zeta = calc_zeta u v flag imax jmax delx dely
>        hPutStr file $ "P6 " ++ (show imax) ++ " " ++ (show jmax) ++ " 255\n"
>        mapM (\(f, z) -> if (f .&. _cf == 0) then writeRGB file 0 255 0
>                         else writeBW file (((abs (z/12.6))**0.4)*255))
>                         (zip (toList $ ignoreBoundary flag)
>                              (toList $ ignoreBoundary zeta))
>        hClose file

> writeBW file b = writeRGB file b b b
> writeRGB file r g b = do hPutChar file $ chr $ truncate r
>                          hPutChar file $ chr $ truncate g
>                          hPutChar file $ chr $ truncate b

