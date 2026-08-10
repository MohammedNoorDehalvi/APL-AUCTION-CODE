'use client';

import React from 'react';
import { motion } from 'framer-motion';

export function FCSBackground({ heroAsset }: { heroAsset: string }) {
  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      transition={{ duration: 1.5 }}
      className="fixed inset-0 z-[-1] w-full h-full overflow-hidden pointer-events-none"
    >
      <div 
        className="absolute inset-0 bg-cover bg-center bg-no-repeat w-full h-full"
        style={{ backgroundImage: `url(${heroAsset})` }}
      />
      {/* Dark overlay to ensure contrast and readability for the stadium background */}
      <div className="absolute inset-0 bg-slate-950/70 backdrop-blur-sm" />
      <div className="absolute inset-0 bg-gradient-to-t from-slate-950 via-slate-950/50 to-transparent" />
    </motion.div>
  );
}
