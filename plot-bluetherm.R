library("RSQLite")

# Sensor 1 is usually the oven
# Sensor 2 is usually the meat

fetchSensorData <- function(time_now, con, sensor_number) {
  epoch_max <- as.integer(time_now)
  epoch_min <- epoch_max - 86400
  table <- paste("sensor_", sensor_number, sep="")
  where <- paste("epoch >=", epoch_min, "AND epoch <=", epoch_max)
  sql <- paste("SELECT epoch, mC FROM", table, "WHERE", where)
  
  res <- dbSendQuery(con, sql)
  data <- fetch(res, n=-1)
  dbClearResult(res)
  return(data)
}

convertRawData <- function(raw_data, start_epoch) {
  return(data.frame(
    time=raw_data$epoch - start_epoch,
    temperature=raw_data$mC / 1000.0
  ))
}

fetchAllData <- function(time_now, sqlite_path) {
  con <- dbConnect(SQLite(), sqlite_path)
  raw_data_1 <- fetchSensorData(time_now, con, 1)
  raw_data_2 <- fetchSensorData(time_now, con, 2)
  dbDisconnect(con)

  start_epoch <- min(
    min(raw_data_1$epoch),
    min(raw_data_2$epoch)
  )

  data_1 <- convertRawData(raw_data_1, start_epoch)
  data_2 <- convertRawData(raw_data_2, start_epoch)

  return(list(
    start_epoch=start_epoch,
    sensors=list(data_1, data_2)
  ))
}

modelRecent <- function(time_now, data, window_size, sensor_number) {
  epoch_now <- as.integer(time_now)
  time_now <- epoch_now - data$start_epoch
  t0 <- time_now - window_size
  recent <- data$sensors[[sensor_number]]
  recent <- recent[recent$time > t0,]
  model <- lm(recent$temperature ~ recent$time)
  return(model)
}

doneTime <- function(meat_model, done_temperature) {
  # Done time
  # meat-model:
  #    temperature = r(time) + i
  # => done-time = (done-temperature - i) / r
  i <- meat_model$coefficients[[1]]
  r <- meat_model$coefficients[[2]]
  return((done_temperature - i) / r)
}

meatGuidelines <- function(start_epoch, meat_model, done_temperature) {
  # Temperature
  abline(done_temperature, 0, lty=3, col=8)
  label <- paste(done_temperature, "\u00B0C", sep="")
  text(0, done_temperature, label, pos=3, col=1)

  # Done time vertical
  done_time <- doneTime(meat_model, done_temperature)
  abline(v=done_time, lt=3, col=8)

  # Done time label
  start_time <- as.POSIXct(start_epoch + done_time, origin="1970-01-01")
  label <- strftime(start_time, '%H:%M')
  text(done_time, done_temperature, label, pos=2, col=1)

  # Done time marker
  points(done_time, done_temperature, type="p", lwd=4, col="cyan")
}

fake_time <- as.POSIXct("2015-10-28 19:24")
meat_temperature_targets <- c(55, 65, 75)
data <- fetchAllData(fake_time, "/var/lib/bluethermd/sqlite")

s1 <- data$sensors[[1]]
s2 <- data$sensors[[2]]

# Predictions, required to get the size of the graph correct
small_window_size <- 300
oven_model <- modelRecent(fake_time, data, small_window_size, 1)
meat_model <- modelRecent(fake_time, data, small_window_size, 2)

# done-times, needed to get scale right
done_times <- numeric(0)
for (t in meat_temperature_targets) {
  done_times <- c(done_times, doneTime(meat_model, t))
}

## BEGIN PLOT
# TODO parse these from the output of fbset(8) ?
png('plot.png', width=1920, height=1080, units="px")

par(cex=3.0, family="mono")

# Current stats, for the subtitle
clock <- strftime(fake_time, "%H:%M")
subtitle <- paste('time=', clock, sep="")

# Plot the basic lines
plot(
  s1$temperature ~ s1$time,
  type="l",
  xlim=range(c(done_times, s1$time)),
  lwd=4,
  main="Tempnalysis",
  sub=subtitle,
  xlab="Cook Time",
  ylab="Temperatue / \u00B0C"
)

points(
  s2$temperature ~ s2$time,
  type="l",
  lwd=4,
)

# Draw on models
abline(oven_model, lt=2, col=4)
abline(meat_model, lt=2, col=4)

# Meat guidelines
meatGuidelines(data$start_epoch, meat_model, 55)
meatGuidelines(data$start_epoch, meat_model, 65)
meatGuidelines(data$start_epoch, meat_model, 75)

dev.off()
