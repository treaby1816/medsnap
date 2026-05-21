import React, { useState } from "react";
import Loader from "./components/ui/animated-scan-loader";

export default function Demo() {
  const [isScanning, setIsScanning] = useState(true);

  return (
    <div className="min-h-screen bg-gray-950 text-white flex flex-col items-center justify-center p-6 font-sans">
      <div className="max-w-md w-full bg-gray-900 border border-gray-800 rounded-3xl p-8 shadow-2xl relative overflow-hidden">
        {/* Decorative corner elements */}
        <div className="absolute top-0 left-0 w-8 h-8 border-t-2 border-l-2 border-red-500 rounded-tl-2xl"></div>
        <div className="absolute top-0 right-0 w-8 h-8 border-t-2 border-r-2 border-red-500 rounded-tr-2xl"></div>
        <div className="absolute bottom-0 left-0 w-8 h-8 border-b-2 border-l-2 border-red-500 rounded-bl-2xl"></div>
        <div className="absolute bottom-0 right-0 w-8 h-8 border-b-2 border-r-2 border-red-500 rounded-br-2xl"></div>

        <div className="flex flex-col items-center gap-6">
          <div className="text-center">
            <h1 className="text-2xl font-bold tracking-tight text-white mb-2">VailMeds Barcode Scanner</h1>
            <p className="text-sm text-gray-400">Position the prescription barcode in the frame below.</p>
          </div>

          {/* Glowing scanner frame */}
          <div className="w-full aspect-square bg-gray-950 border border-gray-800 rounded-2xl flex items-center justify-center relative overflow-hidden group shadow-inner">
            <div className="absolute inset-0 bg-radial-gradient from-red-500/5 to-transparent pointer-events-none"></div>
            
            {isScanning && (
              <div className="flex flex-col items-center gap-4 animate-pulse">
                <Loader />
                <span className="text-xs font-mono uppercase tracking-widest text-red-500">
                  Scanning active...
                </span>
              </div>
            )}

            {!isScanning && (
              <div className="text-center p-4">
                <div className="w-12 h-12 bg-green-500/10 text-green-500 rounded-full flex items-center justify-center mx-auto mb-3">
                  <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                  </svg>
                </div>
                <p className="font-semibold text-green-400">Barcode Read Successfully</p>
                <p className="text-xs text-gray-500 mt-1">Generic Acetaminophen - 500mg</p>
              </div>
            )}
          </div>

          {/* Scanner action button */}
          <button
            onClick={() => setIsScanning(!isScanning)}
            className={`w-full py-3 px-6 rounded-xl font-semibold transition-all duration-300 ${
              isScanning
                ? "bg-red-600 hover:bg-red-500 text-white shadow-lg shadow-red-600/20"
                : "bg-gray-800 hover:bg-gray-700 text-gray-300"
            }`}
          >
            {isScanning ? "Pause Scan" : "Restart Scan"}
          </button>
        </div>
      </div>
    </div>
  );
}
