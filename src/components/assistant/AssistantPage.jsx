import React, { useState } from 'react';
import { Card } from '../ui/Card';

export function AssistantPage() {
  const [message, setMessage] = useState('');

  return (
    <main className="flex-1 min-w-0 overflow-auto">
      <div className="max-w-[1440px] mx-auto h-[calc(100vh-4rem)] flex flex-col animate-fade-in">
        <div className="flex-1 p-4 overflow-auto">
          <div className="space-y-4">
            <div className="flex justify-start">
              <div className="bg-gray-100 dark:bg-dark-hover rounded-2xl px-4 py-2 max-w-[70%]">
                <p className="text-sm">¡Hola! Soy tu asistente virtual. ¿En qué puedo ayudarte?</p>
              </div>
            </div>
          </div>
        </div>

        <div className="p-4 border-t border-gray-100 dark:border-gray-800">
          <form className="flex gap-2" onSubmit={(e) => e.preventDefault()}>
            <input
              type="text"
              value={message}
              onChange={(e) => setMessage(e.target.value)}
              placeholder="Escribe tu mensaje..."
              className="flex-1 px-4 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-dark-hover text-gray-900 dark:text-white placeholder-gray-400 focus:ring-2 focus:ring-primary/20 focus:border-primary"
            />
            <button
              type="submit"
              className="px-4 py-2 bg-primary hover:bg-primary-light text-white font-medium rounded-lg transition-colors"
            >
              Enviar
            </button>
          </form>
        </div>
      </div>
    </main>
  );
}