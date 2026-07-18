const { EventEmitter } = require('events');

/** In-process fan-out for near-realtime booking chat. */
const chatEvents = new EventEmitter();
chatEvents.setMaxListeners(200);

function emitChatMessage(bookingId, message) {
  chatEvents.emit(`booking:${bookingId}`, message);
  chatEvents.emit('message', { bookingId, message });
}

function subscribeBookingChat(bookingId, listener) {
  const event = `booking:${bookingId}`;
  chatEvents.on(event, listener);
  return () => chatEvents.off(event, listener);
}

module.exports = {
  chatEvents,
  emitChatMessage,
  subscribeBookingChat,
};
