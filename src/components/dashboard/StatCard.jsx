import React from 'react';
import { Card } from '../ui/Card';

export function StatCard({ title, value, change, changeType = 'neutral', icon }) {
  const getIcon = () => {
    switch (icon) {
      case 'users':
        return (
          <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" fill="currentColor" viewBox="0 0 256 256">
            <path d="M117.25,157.92a60,60,0,1,0-66.5,0A95.83,95.83,0,0,0,3.53,195.63a8,8,0,1,0,13.89,8A84,84,0,0,1,84,164.51h0a84,84,0,0,1,66.58,39.12,8,8,0,0,0,13.89-8A95.83,95.83,0,0,0,117.25,157.92ZM40,108a44,44,0,1,1,44,44A44.05,44.05,0,0,1,40,108Zm210.47,87.63a8,8,0,0,1-13.89,8A84,84,0,0,0,172,164.51h0a82.45,82.45,0,0,0-19.54,2.32,8,8,0,0,1-3.78-15.55,98.51,98.51,0,0,1,23.32-2.77,95.93,95.93,0,0,1,76.25,37.44A8,8,0,0,1,250.47,195.63ZM132,108a44,44,0,0,1,88,0c0,19.51-16.69,44-44,44C149.86,152,132,127.51,132,108Z" />
          </svg>
        );
      case 'money':
        return (
          <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" fill="currentColor" viewBox="0 0 256 256">
            <path d="M128,88a40,40,0,1,0,40,40A40,40,0,0,0,128,88Zm0,64a24,24,0,1,1,24-24A24,24,0,0,1,128,152ZM216,40H40A16,16,0,0,0,24,56V200a16,16,0,0,0,16,16H216a16,16,0,0,0,16-16V56A16,16,0,0,0,216,40Zm0,160H40V56H216V200ZM176,88a8,8,0,0,1,8-8h16a8,8,0,0,1,0,16H184A8,8,0,0,1,176,88Zm0,80a8,8,0,0,1,8-8h16a8,8,0,0,1,0,16H184A8,8,0,0,1,176,168ZM56,88a8,8,0,0,1,8-8H80a8,8,0,0,1,0,16H64A8,8,0,0,1,56,88Zm0,80a8,8,0,0,1,8-8H80a8,8,0,0,1,0,16H64A8,8,0,0,1,56,168Z" />
          </svg>
        );
      case 'chart':
        return (
          <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" fill="currentColor" viewBox="0 0 256 256">
            <path d="M232,208a8,8,0,0,1-8,8H32a8,8,0,0,1-8-8V48a8,8,0,0,1,16,0V152.81l52.12-52.12a8,8,0,0,1,11.31,0L128,125.25l75.72-75.72a8,8,0,0,1,11.31,11.31l-81.37,81.37a8,8,0,0,1-11.31,0L97.77,117.63,40,175.4V200H224A8,8,0,0,1,232,208Z" />
          </svg>
        );
      case 'alert':
        return (
          <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" fill="currentColor" viewBox="0 0 256 256">
            <path d="M236.8,188.09,149.35,36.22h0a24.76,24.76,0,0,0-42.7,0L19.2,188.09a23.51,23.51,0,0,0,0,23.72A24.35,24.35,0,0,0,40.55,224h174.9a24.35,24.35,0,0,0,21.33-12.19A23.51,23.51,0,0,0,236.8,188.09ZM222.93,203.8a8.5,8.5,0,0,1-7.48,4.2H40.55a8.5,8.5,0,0,1-7.48-4.2,7.59,7.59,0,0,1,0-7.72L120.52,44.21a8.75,8.75,0,0,1,15,0l87.45,151.87A7.59,7.59,0,0,1,222.93,203.8ZM120,144V104a8,8,0,0,1,16,0v40a8,8,0,0,1-16,0Zm20,36a12,12,0,1,1-12-12A12,12,0,0,1,140,180Z" />
          </svg>
        );
      default:
        return null;
    }
  };

  return (
    <Card className="flex items-start gap-4 p-6 hover:shadow-md transition-shadow duration-200">
      {icon && (
        <div className={`p-3 rounded-lg ${
          changeType === 'increase' ? 'bg-red-100 text-red-600' :
          changeType === 'decrease' ? 'bg-emerald-100 text-emerald-600' :
          'bg-primary/10 text-primary'
        }`}>
          {getIcon()}
        </div>
      )}
      <div className="flex-1">
        <p className="text-gray-600 dark:text-gray-300 text-sm font-medium">{title}</p>
        <p className="text-gray-900 dark:text-white text-2xl font-bold mt-1">{value}</p>
        {change && (
          <p className={`text-sm font-medium mt-1 ${
            changeType === 'increase' ? 'text-red-600' :
            changeType === 'decrease' ? 'text-emerald-600' :
            'text-gray-500'
          }`}>
            {change} vs mes anterior
          </p>
        )}
      </div>
    </Card>
  );
}