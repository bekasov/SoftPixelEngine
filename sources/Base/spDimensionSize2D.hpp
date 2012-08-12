/*
 * Size 2D header
 * 
 * This file is part of the "SoftPixel Engine" (Copyright (c) 2008 by Lukas Hermanns)
 * See "SoftPixelEngine.hpp" for license information.
 */

#ifndef __SP_DIMENSION_SIZE2D_H__
#define __SP_DIMENSION_SIZE2D_H__


#include "Base/spStandard.hpp"


namespace sp
{
namespace dim
{


template <typename T> class size2d
{
    
    public:
        
        size2d() :
            Width   (0),
            Height  (0)
        {
        }
        size2d(T Size) :
            Width   (Size),
            Height  (Size)
        {
        }
        size2d(T InitWidth, T InitHeight) :
            Width   (InitWidth  ),
            Height  (InitHeight )
        {
        }
        size2d(const size2d<T> &Other) :
            Width   (Other.Width    ),
            Height  (Other.Height   )
        {
        }
        ~size2d()
        {
        }
        
        /* === Operators - comparisions === */
        
        inline bool operator == (const size2d<T> &Other) const
        {
            return Width == Other.Width && Height == Other.Height;
        }
        inline bool operator != (const size2d<T> &Other) const
        {
            return Width != Other.Width || Height != Other.Height;
        }
        
        //! Returns true if this width and height are greater to the Other.
        inline bool operator > (const size2d<T> &Other) const
        {
            return Width > Other.Width && Height > Other.Height;
        }
        //! Returns true if this width and height are smaller to the Other.
        inline bool operator < (const size2d<T> &Other) const
        {
            return Width < Other.Width && Height < Other.Height;
        }
        
        //! Returns true if this width and height are greater or equal to the Other.
        inline bool operator >= (const size2d<T> &Other) const
        {
            return Width >= Other.Width && Height >= Other.Height;
        }
        //! Returns true if this width and height are small or equal to the Other.
        inline bool operator <= (const size2d<T> &Other) const
        {
            return Width <= Other.Width && Height <= Other.Height;
        }
        
        /* === Operators - addition, subtraction, division, multiplication === */
        
        inline size2d<T> operator + (const size2d<T> &Other) const
        {
            return size2d<T>(Width + Other.Width, Height + Other.Height);
        }
        inline size2d<T>& operator += (const size2d<T> &Other)
        {
            Width += Other.Width; Height += Other.Height; return *this;
        }
        
        inline size2d<T> operator - (const size2d<T> &Other) const
        {
            return size2d<T>(Width - Other.Width, Height - Other.Height);
        }
        inline size2d<T>& operator -= (const size2d<T> &Other)
        {
            Width -= Other.Width; Height -= Other.Height; return *this;
        }
        
        inline size2d<T> operator / (const size2d<T> &Other) const
        {
            return size2d<T>(Width / Other.Width, Height / Other.Height);
        }
        inline size2d<T>& operator /= (const size2d<T> &Other)
        {
            Width /= Other.Width; Height /= Other.Height; return *this;
        }
        
        inline size2d<T> operator * (const size2d<T> &Other) const
        {
            return size2d<T>(Width * Other.Width, Height * Other.Height);
        }
        inline size2d<T>& operator *= (const size2d<T> &Other)
        {
            Width *= Other.Width; Height *= Other.Height; return *this;
        }
        
        inline size2d<T> operator - () const
        {
            return size2d<T>(-Width, -Height);
        }
        
        /* Extra functions */
        
        inline void set(T NewWidth, T NewHeight)
        {
            Width = NewWidth; Height = NewHeight;
        }
        inline void get(T &NewWidth, T &NewHeight) const
        {
            NewWidth = Width; NewHeight = Height;
        }
        
        inline T getArea() const
        {
            return Width * Height;
        }
        
        template <typename B> inline size2d<B> cast() const
        {
            return size2d<B>(static_cast<B>(Width), static_cast<B>(Height));
        }
        
        /* Members */
        
        T Width, Height;
        
};

typedef size2d<s32> size2di;
typedef size2d<f32> size2df;


} // /namespace dim

} // /namespace sp


#endif



// ================================================================================