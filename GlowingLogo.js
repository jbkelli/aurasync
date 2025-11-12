// GlowingLogo.js
import React, { useState, useEffect } from 'react';
import { View, Text, StyleSheet } from 'react-native';
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withSequence,
  withRepeat,
  withTiming,
  Easing,
} from 'react-native-reanimated';

const FULL_TEXT = "Aura Sync";
const TYPING_SPEED_MS = 150; // Milliseconds per letter

// We've added an 'onFinish' prop.
// App.js will give us a function to call when we're done.
export default function GlowingLogo({ onFinish }) {
  // --- Text to display ---
  const [displayText, setDisplayText] = useState('');
  const [isTypingDone, setIsTypingDone] = useState(false);

  // --- Glow Animation (Same as before) ---
  const glow = useSharedValue(0.3);
  useEffect(() => {
    glow.value = withRepeat(
      withSequence(
        withTiming(1.0, {
          duration: 1500,
          easing: Easing.bezier(0.25, 0.1, 0.25, 1),
        }),
        withTiming(0.3, {
          duration: 1500,
          easing: Easing.bezier(0.25, 0.1, 0.25, 1),
        })
      ),
      -1,
      true
    );
  }, [glow]);

  // --- NEW: Blinking Cursor Animation ---
  const cursorOpacity = useSharedValue(1);
  useEffect(() => {
    cursorOpacity.value = withRepeat(
      withSequence(
        withTiming(0, { duration: 300 }),
        withTiming(1, { duration: 300 })
      ),
      -1 // Repeat forever
    );
  }, [cursorOpacity]);

  // --- NEW: Typing Effect Logic ---
  useEffect(() => {
    let index = 0;
    setDisplayText(''); // Start with empty text
    setIsTypingDone(false);

    // This runs a function every 'TYPING_SPEED_MS'
    const typingInterval = setInterval(() => {
      if (index < FULL_TEXT.length) {
        // Add one letter to the text
        setDisplayText(FULL_TEXT.substring(0, index + 1));
        index++;
      } else {
        // We're done typing
        clearInterval(typingInterval);
        setIsTypingDone(true); // This will hide the cursor

        // Wait 1.5 seconds *after* typing, then call onFinish
        setTimeout(() => {
          onFinish();
        }, 1500);
      }
    }, TYPING_SPEED_MS);

    // Cleanup function
    return () => clearInterval(typingInterval);
  }, [onFinish]);

  // --- Animated Styles (Glow + Cursor) ---
  const animatedGlowStyle = useAnimatedStyle(() => {
    return {
      textShadowColor: `rgba(66, 139, 202, ${glow.value})`,
      textShadowOffset: { width: 0, height: 0 },
      textShadowRadius: 5,
      color: '#428bca',
    };
  });

  const animatedCursorStyle = useAnimatedStyle(() => {
    return { opacity: cursorOpacity.value };
  });

  // --- Render ---
  const AnimatedText = Animated.createAnimatedComponent(Text);

  return (
    <View style={styles.container}>
      <AnimatedText style={[styles.text, animatedGlowStyle]}>
        {displayText}
        {!isTypingDone && (
          <Animated.Text style={[styles.cursor, animatedCursorStyle]}>
            _
          </Animated.Text>
        )}
      </AnimatedText>
    </View>
  );
}

// --- Styles ---
const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#1E1E1E',
  },
  text: {
    fontSize: 52,
    fontWeight: 'bold',
  },
  // NEW: Style for the cursor
  cursor: {
    fontSize: 52,
    fontWeight: 'bold',
    color: '#428bca', // Match the glow color
  },
});