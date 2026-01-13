import React, { useEffect, useState, useRef } from "react";
import { 
  View, 
  StyleSheet, 
  Text, 
  FlatList, 
  TouchableOpacity, 
  Alert,
  Platform,
  PermissionsAndroid 
} from 'react-native';
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withRepeat,
  withTiming,
  Easing,
  interpolate,
  withSequence,
} from 'react-native-reanimated';

import { BleManager } from "react-native-ble-plx";
import { Audio } from 'expo-av';


//Rendering 3 pulses to make a radar
function Pulse({delay = 0}){

  //creating shred value for the animation
  const animation = useSharedValue(0);

  //starting the animation when the component loads
  useEffect(() => {
    animation.value = withRepeat(
      //Going from 0 to 1 over 3 seconds
      withSequence(

        //Adding a delay wrapper
        withTiming(0, { duration: delay }),
        withTiming(1, {
          duration: 3000,
          easing: Easing.out(Easing.ease), //start fast, slow down
        })
      ),
      -1, //repeat infinitely
      false //no reversing
    );
  }, [animation, delay]);

  const animatedStyle = useAnimatedStyle(() => {
    //Scaling and opacity
    const scale = interpolate(
      animation.value,
      [0, 1],
      [0.5, 3]
    );

    //Opacity decreases as the animation value increases
    const opacity = interpolate(
      animation.value,
      [0, 1],
      [0.6, 0]
    );

    return {
      transform: [{scale: scale}],
      opacity: opacity,
    };
  });

  //returning the animation pulse ring
  return <Animated.View style={[styles.pulse, animatedStyle]} />;
}


//Main screen
export default function MainApp(){
  const [isScanning, setIsScanning] = useState(false);
  const [devices, setDevices] = useState([]);
  const [permissionsGranted, setPermissionsGranted] = useState(false);
  const bleManagerRef = useRef(null);

  useEffect(() => {
    // Initialize BLE Manager
    bleManagerRef.current = new BleManager();
    
    requestPermissions();

    return () => {
      // Cleanup
      if (bleManagerRef.current) {
        bleManagerRef.current.stopDeviceScan();
        bleManagerRef.current.destroy();
      }
    };
  }, []);

  const requestPermissions = async () => {
    if (Platform.OS === 'android') {
      try {
        if (Platform.Version >= 31) {
          // Android 12+
          const granted = await PermissionsAndroid.requestMultiple([
            PermissionsAndroid.PERMISSIONS.BLUETOOTH_SCAN,
            PermissionsAndroid.PERMISSIONS.BLUETOOTH_CONNECT,
            PermissionsAndroid.PERMISSIONS.ACCESS_FINE_LOCATION,
          ]);

          const allGranted = Object.values(granted).every(
            status => status === PermissionsAndroid.RESULTS.GRANTED
          );

          setPermissionsGranted(allGranted);
          
          if (allGranted) {
            startScanning();
          } else {
            Alert.alert('Permissions Required', 'Bluetooth and location permissions are needed to discover nearby devices.');
          }
        } else {
          // Android 11 and below
          const granted = await PermissionsAndroid.requestMultiple([
            PermissionsAndroid.PERMISSIONS.ACCESS_FINE_LOCATION,
            PermissionsAndroid.PERMISSIONS.BLUETOOTH,
            PermissionsAndroid.PERMISSIONS.BLUETOOTH_ADMIN,
          ]);

          const allGranted = Object.values(granted).every(
            status => status === PermissionsAndroid.RESULTS.GRANTED
          );

          setPermissionsGranted(allGranted);
          
          if (allGranted) {
            startScanning();
          } else {
            Alert.alert('Permissions Required', 'Bluetooth and location permissions are needed.');
          }
        }
      } catch (err) {
        console.warn(err);
        Alert.alert('Error', 'Failed to request permissions');
      }
    } else {
      // iOS - permissions handled by Info.plist
      setPermissionsGranted(true);
      startScanning();
    }
  };

  const startScanning = () => {
    if (!bleManagerRef.current || isScanning) return;

    setIsScanning(true);
    setDevices([]);

    console.log('Starting BLE scan...');

    bleManagerRef.current.startDeviceScan(null, null, (error, device) => {
      if (error) {
        console.error('Scan error:', error);
        setIsScanning(false);
        Alert.alert('Scan Error', error.message);
        return;
      }

      if (device && device.name) {
        setDevices(prevDevices => {
          // Check if device already exists
          const exists = prevDevices.find(d => d.id === device.id);
          if (exists) {
            return prevDevices;
          }
          
          console.log('Found device:', device.name, device.id);
          return [...prevDevices, {
            id: device.id,
            name: device.name,
            rssi: device.rssi
          }];
        });
      }
    });

    // Stop scanning after 10 seconds
    setTimeout(() => {
      stopScanning();
    }, 10000);
  };

  const stopScanning = () => {
    if (bleManagerRef.current) {
      bleManagerRef.current.stopDeviceScan();
      setIsScanning(false);
      console.log('Stopped scanning');
    }
  };

  const handleDevicePress = async (device) => {
    Alert.alert(
      'Connect to Device',
      `Do you want to connect to ${device.name}?`,
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Connect',
          onPress: () => connectToDevice(device),
        },
      ]
    );
  };

  const connectToDevice = async (device) => {
    try {
      console.log('Connecting to', device.name);
      // We'll implement actual connection logic here
      Alert.alert('Success', `Connecting to ${device.name}...`);
    } catch (error) {
      console.error('Connection error:', error);
      Alert.alert('Error', 'Failed to connect to device');
    }
  };

  const renderDevice = ({ item }) => (
    <TouchableOpacity 
      style={styles.deviceItem}
      onPress={() => handleDevicePress(item)}
    >
      <View style={styles.deviceInfo}>
        <Text style={styles.deviceName}>{item.name}</Text>
        <Text style={styles.deviceId}>{item.id}</Text>
        <Text style={styles.deviceRssi}>Signal: {item.rssi} dBm</Text>
      </View>
    </TouchableOpacity>
  );

  return (
    <View style={styles.container}>
      {/* Radar Animation */}
      <View style={styles.radarContainer}>
        <Pulse delay={0} />
        <Pulse delay={1000} />
        <Pulse delay={2000} />
        
        <View style={styles.centerDot}>
          <Animated.Text style={styles.centerText}>YOU</Animated.Text>
        </View>
      </View>

      {/* Device List */}
      <View style={styles.deviceListContainer}>
        <View style={styles.header}>
          <Text style={styles.headerText}>
            {isScanning ? 'Scanning for devices...' : `Found ${devices.length} device(s)`}
          </Text>
          <TouchableOpacity 
            style={styles.scanButton}
            onPress={isScanning ? stopScanning : startScanning}
          >
            <Text style={styles.scanButtonText}>
              {isScanning ? 'Stop' : 'Scan'}
            </Text>
          </TouchableOpacity>
        </View>

        {devices.length === 0 && !isScanning && (
          <Text style={styles.emptyText}>
            No devices found. Tap Scan to search for nearby devices.
          </Text>
        )}

        <FlatList
          data={devices}
          renderItem={renderDevice}
          keyExtractor={item => item.id}
          style={styles.deviceList}
        />
      </View>
    </View>
  );
}


//Our styles
const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#1E1E1E', 
  },

  radarContainer: {
    height: '40%',
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#1E1E1E',
  },

  pulse: {
    position: 'absolute',
    width: 150,
    height: 150,
    backgroundColor: '#428bca',
    borderRadius: 75,
    borderWidth: 2,
    borderColor: 'rgba(66, 139, 202, 0.5)',
  },

  centerDot: {
    width: 100,
    height: 100,
    backgroundColor: '#428bca',
    borderRadius: 50,
    justifyContent: 'center',
    alignItems: 'center',
    shadowColor: '#428bca',
    shadowRadius: 20,
    shadowOpacity: 0.8,
    elevation: 10,
  },

  centerText: {
    color: 'white',
    fontSize: 20,
    fontWeight: 'bold',
  },

  deviceListContainer: {
    flex: 1,
    backgroundColor: '#2A2A2A',
    borderTopLeftRadius: 30,
    borderTopRightRadius: 30,
    padding: 20,
    marginTop: -30,
  },

  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 15,
  },

  headerText: {
    color: 'white',
    fontSize: 16,
    fontWeight: '600',
  },

  scanButton: {
    backgroundColor: '#428bca',
    paddingHorizontal: 20,
    paddingVertical: 10,
    borderRadius: 20,
  },

  scanButtonText: {
    color: 'white',
    fontWeight: 'bold',
  },

  deviceList: {
    flex: 1,
  },

  deviceItem: {
    backgroundColor: '#3A3A3A',
    padding: 15,
    borderRadius: 10,
    marginBottom: 10,
  },

  deviceInfo: {
    flex: 1,
  },

  deviceName: {
    color: 'white',
    fontSize: 18,
    fontWeight: 'bold',
    marginBottom: 5,
  },

  deviceId: {
    color: '#999',
    fontSize: 12,
    marginBottom: 3,
  },

  deviceRssi: {
    color: '#428bca',
    fontSize: 14,
  },

  emptyText: {
    color: '#666',
    textAlign: 'center',
    marginTop: 20,
    fontSize: 14,
  },
});