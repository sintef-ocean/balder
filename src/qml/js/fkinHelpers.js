
function zoomToFrame(range, min_fov, axis, percent)
{
  if(range.x < min_fov.x)
    axis.min = range.x - (min_fov.y - min_fov.x)*percent;
  else
    axis.min = min_fov.x;
  if(range.y > min_fov.y)
    axis.max = range.y + (min_fov.y - min_fov.x)*percent;
  else
    axis.max = min_fov.y;
}

function toMSecsSinceEpoch(date)
{
  var msecs = date.getTime();
  return msecs;
}

function ensureTimeHorizon(timeChart, horizonMS, futureMS, t_min, t_max)
{
  if (timeChart.axes.length < 2)
    console.log("There are no axes to adjust the time horizon");

  // how to know if it is a time axis?
  // assume for now Qt.Horizontal is time

  var Tidx = 0;
  for (var i = 0; i < timeChart.axes.length; ++i)
  {
    if (timeChart.axes[i].orientation == Qt.Horizontal)
      Tidx = i;
  }

  timeChart.axes[Tidx].max = new Date(timeChart.axes[Tidx].max.getTime() + futureMS);

  var diff = t_max.getTime() - t_max.getTime()
  if (diff < horizonMS)
    timeChart.axes[Tidx].min = new Date(t_max.getTime() - horizonMS + futureMS);
  //timeChart.axes[Tidx].min = new Date(timeChart.axes[Tidx].max.getTime() - horizonMS);

}

function zoomToFrame(range, min_fov, axis, percent)
{
  if(range.x < min_fov.x)
    axis.min = range.x - (min_fov.y - min_fov.x)*percent;
  else
    axis.min = min_fov.x;
  if(range.y > min_fov.y)
    axis.max = range.y + (min_fov.y - min_fov.x)*percent;
  else
    axis.max = min_fov.y;
}

function makeEqualAxis(chart)//, point)
{
  //extendAxes(chart, point);

  if (chart.axes.length < 2)
    console.log("The chart does not have enough axes to perform equal axes calculation");

  var Xidx, Yidx;
  for (var i = 0; i < chart.axes.length; ++i)
  {
    if (chart.axes[i].orientation == Qt.Horizontal)
      Xidx = i;
    else
      Yidx = i;
  }

  if (chart.axes.length > 2)
    console.log("Equal axes calculation is not designed for more than 2 axes. Unexplained behavior follows");

  // Ensure equal scaling of value in axes wrt. plot area width/height ratio
  var diff_x = chart.axes[Xidx].max - chart.axes[Xidx].min;
  var diff_y = chart.axes[Yidx].max - chart.axes[Yidx].min;
  var ratioScreen = chart.plotArea.width/chart.plotArea.height;
  var ratio = ratioScreen/(diff_x/diff_y);


  // Objective: ratio = 1.
  if (ratio > 1 + 1e-3) // increase x-range to reduce y-stretchiness
  {
    // (diff_x + w)/diff_y = ratioScreen, solve wrt w. Extend max and min
    var w = ratioScreen*diff_y - diff_x;
    chart.axes[Xidx].max += 0.5*w;
    chart.axes[Xidx].min -= 0.5*w;
  }
  else if (ratio < 1 - 1e-3) // increase y-range to reduce x-stretchiness
  {
    // (diff_x)/(diff_y + w) = ratioScreen, solve wrt w. Extend max and min
    var w = diff_x/ratioScreen - diff_y;
    chart.axes[Yidx].max += 0.5*w;
    chart.axes[Yidx].min -= 0.5*w;
  }
}

// not currently used
function moveTimeHorizon(timeChart, inputSignal)
{
  timeChart.timeSeries1.axisX.min =
    new Date(inputSignal.timestamp.getTime() - timeChart.timeSeries1.horizonMS);
  timeChart.timeSeries1.axisX.max =
    new Date(inputSignal.timestamp.getTime() + timeChart.timeSeries1.futureMS);
}

// not currently used
function moveXHorizon(timeChart, value, horizon)
{
  timeChart.timeSeries1.axisX.min = value - horizon;
  timeChart.timeSeries1.axisX.max = value;
}

// not currently used
function extendAxes(chart, point)
{
  // Extend X-axis to include new point
  if(chart.timeSeries1.axisX.min > point.x)
    chart.timeSeries1.axisX.min = point.x;
  if(chart.timeSeries1.axisX.max < point.x)
    chart.timeSeries1.axisX.max = point.x;

  // Extend Y-axis to include new point
  if(chart.timeSeries1.axisY.min > point.y)
    chart.timeSeries1.axisY.min = point.y;
  if(chart.timeSeries1.axisY.max < point.y)
    chart.timeSeries1.axisY.max = point.y;
}

// not currently used
function removeOldData(chart, series)
{
  // Removes samples that are outside the view of the x-axis
  // not sure if this matters, though, as the container index still increases..
  var theSeries = chart.series(series);
  var tailStart = theSeries.tailIdxX;
  var tail = tailStart;
  var minNow = chart.axisX(theSeries).min;
  console.log("Started at " + tail);
  for(; tail < tailStart + theSeries.newCountX; ++tail)
  {
    if(theSeries.at(tail).x < minNow)
    {
      theSeries.remove(tail);
    }
    else
      break;
  }
  console.log("Stopped at " + tail);
  var diff = tail - tailStart;
  theSeries.tailIdxX = tail;
  theSeries.newCountX -= diff;
}

// not currently used
function autoScaleAxisY(chart, series, point)
{

  var theSeries = chart.series(series);
  const olddiff = theSeries.axisY.max - theSeries.axisY.min;

  if(point > theSeries.axisY.max)
    theSeries.axisY.max = point + theSeries.y_margin*olddiff;
  if(point < theSeries.axisY.min)
    theSeries.axisY.min = point - theSeries.y_margin*olddiff;
}
