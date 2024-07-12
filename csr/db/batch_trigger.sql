set define off
CREATE OR REPLACE AND COMPILE JAVA SOURCE NAMED csr."BatchTrigger" AS

import java.io.*;
import java.net.*;
import java.sql.*;
import java.util.*;

import oracle.jdbc.*;
import oracle.sql.*;

public class BatchTrigger {

	static class InetSocketAddressComparator implements Comparator<InetSocketAddress>
	{
		public int compare(InetSocketAddress o1, InetSocketAddress o2)
		{
			if (o1 == o2)
				return 0;

			byte[] addr1 = o1.getAddress().getAddress();
			byte[] addr2 = o2.getAddress().getAddress();
			if (addr1.length < addr2.length)
				return -1;
			if (addr1.length > addr2.length)
				return 1;

			for (int i = 0; i < addr1.length; ++i)
			{
				if (addr1[i] < addr2[i])
					return -1;
				if (addr1[i] > addr2[i])
					return 1;
			}
			int port1 = o1.getPort();
			int port2 = o2.getPort();
			return port1 < port2 ? -1 : port1 > port2 ? 1 : 0;
		}
	}

	public static InetSocketAddress parseAddress(String address,
		int defaultPort) throws UnknownHostException
	{
		address = address.trim();
		int portPos = address.indexOf(':');
		int port = defaultPort;
		if (portPos > -1)
		{
			String portStr = address.substring(portPos + 1).trim();
			port = portStr.equals("*") ? defaultPort : Integer.parseInt(portStr);
			address = address.substring(0, portPos);
		}
		InetAddress ipAddress = InetAddress.getByName(address.equals("*") ? "255.255.255.255" : address);
		return new InetSocketAddress(ipAddress, port);
	}

	private static Set<InetSocketAddress> parseAddresses(String addressList,
		List<InetAddress> allAddresses, int defaultPort) throws UnknownHostException
	{
		Set<InetSocketAddress> addresses = new TreeSet<InetSocketAddress>(new InetSocketAddressComparator());
		for (String address : addressList.split(","))
		{
			InetSocketAddress ipAddress = parseAddress(address, defaultPort);
			byte[] addr = ipAddress.getAddress().getAddress();
			if (addr[0] == (byte)0xff && addr[1] == (byte)0xff && addr[2] == (byte)0xff && addr[3] == (byte)0xff)
			{
				for (InetAddress ip : allAddresses)
				{
					addresses.add(new InetSocketAddress(ip, defaultPort));
				}
			}
			else
			{
				addresses.add(ipAddress);
			}
		}
		return addresses;
	}

    public static void send (String broadcastAddresses, int defaultPort, long value)
        throws java.net.SocketException, java.io.IOException, java.lang.InterruptedException, java.sql.SQLException
	{
		OracleConnection conn = (OracleConnection)DriverManager.getConnection("jdbc:default:connection:");

		PreparedStatement stmt = null;
		ResultSet rset = null;
		String batchUdpNotifyCommand = null;
		try
		{
			stmt = conn.prepareStatement(
				"SELECT batch_udp_notify_command, batch_udp_broadcast_addresses " +
				  "FROM csr.db_config ");
			rset = stmt.executeQuery();
			if (rset.next())
			{
				String newBroadcastAddresses = rset.getString("BATCH_UDP_BROADCAST_ADDRESSES");
				if (newBroadcastAddresses != null && newBroadcastAddresses.length() > 0)
					broadcastAddresses = newBroadcastAddresses;
				batchUdpNotifyCommand = rset.getString("BATCH_UDP_NOTIFY_COMMAND");
			}
		}
		finally
		{
			if (rset != null)
				rset.close();
			if (stmt != null)
				stmt.close();
		}

		if (batchUdpNotifyCommand != null && batchUdpNotifyCommand.length() > 0)
		{
			Process p = Runtime.getRuntime().exec(batchUdpNotifyCommand);
			p.waitFor();
			return;
		}

		List<InetAddress> allBroadcastAddresses = new ArrayList<InetAddress>();
		boolean sawNPE = false;
		for (Enumeration<NetworkInterface> interfaces = NetworkInterface.getNetworkInterfaces();
			 interfaces.hasMoreElements(); )
		{
			NetworkInterface networkInterface = interfaces.nextElement();

			// System.out.printf("Interface: %s: ", networkInterface.getDisplayName() + ", up: " + (networkInterface.isUp() ? "yes" : "no"));

			// skips if the current interface is down
			if (!networkInterface.isUp())
				continue;

			// getInterfaceAddresses throws a NullPointerException sometimes, see:
			// http://bugs.java.com/bugdatabase/view_bug.do?bug_id=8023649
			// I don't think it likes bridges much. sigh.
			List<InterfaceAddress> ifAddrs = null;
			try
			{
				ifAddrs = networkInterface.getInterfaceAddresses();
			}
			catch (NullPointerException e)
			{
				// System.out.print("NullPointerException in getInterfaceAddresses: ");
				sawNPE = true;
			}

			if (ifAddrs != null)
			{
				for (InterfaceAddress interfaceAddress : ifAddrs)
				{
					InetAddress broadcast = interfaceAddress.getBroadcast();

					// This IP is a broadcast address
					if (broadcast != null)
					{
						allBroadcastAddresses.add(broadcast);
						// System.out.print("found broadcast: " + broadcast.getHostAddress());
					}
				}
			}
			else
			{
				// try using the addresses, and constructing the broadcast address
				for (Enumeration<InetAddress> addresses = networkInterface.getInetAddresses();
					 addresses.hasMoreElements(); )
				{
					InetAddress addr = addresses.nextElement();
					if (addr instanceof Inet4Address)
					{
						// debugMessage.append("ipv4: "+ addr.getHostAddress());
						byte[] addrBytes = addr.getAddress();
						if (addrBytes[0] == 10 || (addrBytes[0] == 172 && addrBytes[1] == 16) ||
							(addrBytes[0] == 192 && addrBytes[1] == 168))
						{
							addrBytes[3] = (byte)255;
							InetAddress broadcast = InetAddress.getByAddress(addrBytes);
							// System.out.printf("guessed at broadcast: %s\n", broadcast.getHostAddress());
							allBroadcastAddresses.add(broadcast);
						}
					}
				}
			}
		}

		if (broadcastAddresses == null)
			broadcastAddresses = "255.255.255.255:" + Integer.toString(defaultPort);
		Set<InetSocketAddress> parsedAddresses = parseAddresses(broadcastAddresses, allBroadcastAddresses, defaultPort);
		if (sawNPE || parsedAddresses.size() == 0)
		{
			// System.out.print("adding 255.255.255.255 as NPE caught or no addresses found");
			parsedAddresses.add(new InetSocketAddress(InetAddress.getByName("255.255.255.255"), defaultPort));
		}

		byte[] data = new byte[] {
			(byte)(value >> 56),
			(byte)(value >> 48),
			(byte)(value >> 40),
			(byte)(value >> 32),
			(byte)(value >> 24),
			(byte)(value >> 16),
			(byte)(value >> 8),
			(byte)(value)
		};
        DatagramSocket socket = new DatagramSocket();
		for (InetSocketAddress addr : parsedAddresses)
		{
			// System.out.printf("address = %s\n", addr);
		    DatagramPacket packet = new DatagramPacket(data, data.length, addr.getAddress(), addr.getPort());
		    packet.setData(data);
		    socket.send(packet);
		}
    }
};
/
