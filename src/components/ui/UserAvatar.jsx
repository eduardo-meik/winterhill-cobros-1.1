import React from 'react';

function stringToColor(string) {
  let hash = 0;
  for (let i = 0; i < string.length; i++) {
    hash = string.charCodeAt(i) + ((hash << 5) - hash);
  }
  
  const hue = Math.abs(hash % 360);
  return `hsl(${hue}, 70%, 50%)`;
}

function getInitials(name) {
  if (!name) return '?';
  
  const parts = name.trim().split(/\s+/);
  if (parts.length === 1) {
    return parts[0].charAt(0).toUpperCase();
  }
  
  return (parts[0].charAt(0) + parts[parts.length - 1].charAt(0)).toUpperCase();
}

export function UserAvatar({ name, imageUrl, size = 'md', className = '' }) {
  const sizeClasses = {
    sm: 'w-8 h-8 text-sm',
    md: 'w-10 h-10 text-base',
    lg: 'w-12 h-12 text-lg'
  };

  if (imageUrl) {
    return (
      <img
        src={imageUrl}
        alt={name || 'User avatar'}
        className={`rounded-full object-cover ${sizeClasses[size]} ${className}`}
      />
    );
  }

  const backgroundColor = name ? stringToColor(name) : '#4f46e5';
  const initials = getInitials(name);

  return (
    <div
      className={`rounded-full flex items-center justify-center font-medium text-white ${sizeClasses[size]} ${className}`}
      style={{ backgroundColor }}
    >
      {initials}
    </div>
  );
}