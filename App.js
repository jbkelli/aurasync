// App.js
import React, { useState, useCallback } from 'react'; // 1. Import useCallback
import { StatusBar } from 'expo-status-bar';
import GlowingLogo from './GlowingLogo';
import MainApp from './MainApp';

export default function App() {
  const [isAppReady, setIsAppReady] = useState(false);

  // 2. Wrap the function in useCallback
  const handleAnimationFinish = useCallback(() => {
    // Now this function will not be "recreated" on every render
    setIsAppReady(true);
  }, []); // 3. The empty '[]' means this function *never* changes

  return (
    <>
      {isAppReady ? (
        <MainApp />
      ) : (
        // 4. We pass the "locked" function
        <GlowingLogo onFinish={handleAnimationFinish} />
      )}
      <StatusBar style="light" />
    </>
  );
}