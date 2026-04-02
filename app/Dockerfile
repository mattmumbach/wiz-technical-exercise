# Use Node.js 18 Alpine (Lightweight)
FROM node:18-alpine

# Create app directory
WORKDIR /usr/src/app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install --production

# Copy application code and the special txt file
COPY . .

# Expose port
EXPOSE 3000

# Run the app
CMD ["npm", "start"]
