/*
 * Network address header
 * 
 * This file is part of the "SoftPixel Engine" (Copyright (c) 2008 by Lukas Hermanns)
 * See "SoftPixelEngine.hpp" for license information.
 */

#ifndef __SP_NETWORK_ADDRESS_H__
#define __SP_NETWORK_ADDRESS_H__


#include "Base/spStandard.hpp"

#ifdef SP_COMPILE_WITH_NETWORKSYSTEM


#include "Base/spInputOutputString.hpp"
#include "Framework/Network/spNetworkCore.hpp"


namespace sp
{
namespace network
{


//! Network address classes.
enum ENetworkAddressClasses
{
    NETADDRESS_CLASS_UNKNOWN,   //!< Unknown network address class.
    NETADDRESS_CLASS_A,         //!< Network address class A has the net-mask 255.0.0.0.
    NETADDRESS_CLASS_B,         //!< Network address class B has the net-mask 255.255.0.0.
    NETADDRESS_CLASS_C,         //!< Network address class C has the net-mask 255.255.255.0.
};


class NetworkAddress
{
    
    public:
        
        NetworkAddress(const sockaddr_in &SocketAddress);
        NetworkAddress(u16 Port);
        NetworkAddress(u16 Port, u32 IPAddress);
        NetworkAddress(u16 Port, const io::stringc &IPAddress);
        NetworkAddress(const NetworkAddress &Address);
        ~NetworkAddress();
        
        /* Functions */
        
        //! Returns the network port.
        u16 getPort() const;
        
        //! Returns the IP address name (e.g. "127.0.0.1").
        io::stringc getIPAddressName() const;
        
        //! Returns the address descriptions (e.g. "127.0.0.1 : 8000");
        io::stringc getDescription() const;
        
        //! Returns the network address class.
        ENetworkAddressClasses getAddressClass() const;
        
        /* Inline functions */
        
        //! Returns the IP address value.
        inline u32 getIPAddress() const
        {
            return Addr_.sin_addr.s_addr;
        }
        
        inline const sockaddr_in& getSocketAddress() const
        {
            return Addr_;
        }
        inline sockaddr_in& getSocketAddress()
        {
            return Addr_;
        }
        
    private:
        
        /* Members */
        
        sockaddr_in Addr_;
        
};


} // /namespace network

} // /namespace sp


#endif

#endif



// ================================================================================
