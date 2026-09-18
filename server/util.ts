export function getRandomInt() {
  const array = new Uint32Array(1);
  self.crypto.getRandomValues(array);
  return array[0];
}

export const dateFormatter = new Intl.DateTimeFormat('en-US', {
  year: 'numeric',
  month: '2-digit',
  day: '2-digit',
  hour: '2-digit',
  minute: '2-digit',
  second: '2-digit',
  hour12: false // Ensures 24-hour format
});

export const startTime = new Date()

export function asString(data: any): string {
  let result:any = data ?? ''
  return result.toString().trim()
}
