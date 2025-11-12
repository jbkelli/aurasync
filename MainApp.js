import React, { useEffect } from "react";
import { View, StyleSheet } from 'react-native';
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
import { request, PERMISSIONS, RESULTS } from 'react-native-permissions'


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
  return (
    <View style={styles.container}>
      {/* We render the pulse */}
      <Pulse delay={0} />
      <Pulse delay={1000} />
      <Pulse delay={2000} />

      {/* This is the center representing the current user */}
      <View style={styles.centerDot}>
        <Animated.Text style={styles.centerText}>YOU</Animated.Text>
      </View>
    </View>
  );
}


//Our styles
const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#1E1E1E', 
  },

  pulse: {
    //The ring that appears
    position: 'absolute',
    width: 150,
    height: 150,
    backgroundColor: '#428bca',
    borderRadius: 75,
    borderWidth: 2,
    borderColor: 'rgba(66, 139, 202, 0.5)',
  },

  centerDot: {
    //The dot representing current user
    width: 100,
    height: 100,
    backgroundColor: '#428bca',
    borderRadius: 50,
    justifyContent: 'center',
    alignItems: 'center',

    //Adding a glow to the center dot
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
});