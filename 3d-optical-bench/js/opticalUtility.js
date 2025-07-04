let currentLineIdx = 0; 
var secondIsConcave = 1; // this is 1 if the second lens is concave, -1 if convex

let MAX_LINES_SIZE = 10; 
var lineLocations = ["point1", "point2", "color"];
// var convexLocations = ["sphere1", "sphere2"];
// var concaveLocations = ["sphere1", "sphere2", "box"];
// var opticalLocations = [
//     ...convexLocations.flatMap(location => ["convexLens." + location]),
//     ...concaveLocations.flatMap(location => ["concaveLens." + location]),
//     "isConvex", "isTransitioning", "thickness", "angle", "focalLength",
// ]
var structs = { uniform: { lines: [], focalLengths: [] } }
console.log(structs)
let zAngleOffset = 0; 

function initializeLines(gl) {
    for (var i = 0; i < MAX_LINES_SIZE; i++) {
        var locations = {} 
        for (var j = 0; j < lineLocations.length; j++) {
            var field = lineLocations[j];
            var locationName = `lines.at[${i}].${field}`;
            locations[field] = gl.getUniformLocation(gl.program, locationName);
        }
        structs.uniform.lines.push(locations);
    }
}

function initializeOpticalComponents(gl) {
    structs.uniform.focalLengths.push( gl.getUniformLocation(gl.program, "focalLengths") ); 
    let focalLength = structs.uniform.focalLengths[0];
    gl.uniform1f(focalLength, -0.2);
    // for (var i = 0; i < MAX_LINES_SIZE; i++) {
    //     var locations = {} 
    //     for (var j = 0; j < opticalLocations.length; j++) {
    //         var field = opticalLocations[j];
    //         var locationName = `opticalComponents.at[${i}].${field}`;
    //         locations[field] = gl.getUniformLocation(gl.program, locationName);
    //     }
    //     structs.uniform.opticalComponents.push(locations);
    // }
}

function clearLines() {
    currentLineIdx = 0;
}

function drawLines(gl) {
    var xMax = 10, yMax = 10;
    var xLens1 = -2, xLens2 = 1; 
    var xLineS = -5; 

    clearLines();
    var a1 = 0.1 + lens1L.value * 0.03; 
    var a2 = 0.05 + (a1 - 0.1) * (0.93333333);
    var yLine1 = (a1-0.1) + 0.35;
    var yLine2 = a2 + 0.2;
    var yLine3Factor = secondIsConcave;
    var yLine3 = yLine3Factor * a1 * 2 + yLine3Factor * 0.5;

    var zline0 = -5; var zline1 = zline0 + zAngleOffset; var zline2 = zline1 + zAngleOffset; var zline3 = zline2 + zAngleOffset;
    var linepoints = [
        [xLineS,0,zline0],[xLens1,yLine1,zline1],
        [xLens2,yLine2,zline2],
        [3,yLine3,zline3],
    ]    
    if (zAngleOffset > 0.5 || zAngleOffset < -0.5) {
        var gradient = 0.5 * (zline3 - zline0) / (3 - xLens2); // Corrected xLens2 instead of xLineS
        zline1 = zline0 + gradient * (xLens1 - xLineS);
        zline2 = zline1 + gradient * (xLens2 - xLineS);
        zline3 = zline2 + gradient * (3 - xLineS);
    
        linepoints = [
            [xLineS, 0, zline0],
            [xLens1, yLine1, zline1],
            [xLens2, yLine2, zline2],
            [3, yLine3, zline3]
        ];
        }


    var oppLinePoints = [] 
    for (var i = 0; i < linepoints.length; i++) {
        oppLinePoints.push([linepoints[i][0], -linepoints[i][1], linepoints[i][2]]);
    }



    for (var i = 0; i < linepoints.length - 1; i+=1) {
        console.log(yLine2, a2)
        addLine(linepoints[i], linepoints[i+1], [1,0,0], gl, structs);
    }
    for (var i = 0; i < oppLinePoints.length - 1; i+=1) {
        addLine(oppLinePoints[i], oppLinePoints[i+1], [0,0,1], gl, structs);
    }
}

function addLine(from, to, color = [1,0,0], gl, structs) {
    let line = structs.uniform.lines[currentLineIdx];
    if (line == undefined) { console.log("ERROR: line is undefined"); return; }
    gl.uniform3fv(line.point1, from);
    gl.uniform3fv(line.point2, to);
    gl.uniform3fv(line.color, color);
    currentLineIdx++;
}   

function lerp( a, b, alpha ) {
    return a + alpha * (b-a);
}
   

// function addOptics(coordinate = [0,0,0], isConvex = true, unadjustedThickness = 1) {
//     // let opticalComponentAddr = structs.uniform.opticalComponents[currentLineIdx];
//     // gl.uniform3fv(opticalComponentAddr.convexLens.sphere1, coordinate);
//     // gl.uniform3fv(opticalComponentAddr.convexLens.sphere2, coordinate);
//     // gl.uniform3fv(opticalComponentAddr.concaveLens.sphere1, coordinate);
//     // gl.uniform3fv(opticalComponentAddr.concaveLens.sphere2, coordinate);
//     // gl.uniform3fv(opticalComponentAddr.concaveLens.box, coordinate);
//     // gl.uniform1i(opticalComponentAddr.isConvex, isConvex);
//     // gl.uniform1i(opticalComponentAddr.isTransitioning, false);
//     // gl.uniform1f(opticalComponentAddr.thickness, unadjustedThickness);
//     // gl.uniform1f(opticalComponentAddr.angle, 0);
//     // gl.uniform1f(opticalComponentAddr.focalLength, 0);
//     // currentLineIdx++;
// }

function makeTransition() {
    // over the span of x seconds, make secondisconcave linearly go from (1, -1) or (-1, 1)
    var startTime = Date.now() / 1000;
    var initial = secondIsConcave; 
    var intervalId = setInterval(() => {
        var elapsed = Date.now() / 1000 - startTime;
        var alpha = elapsed / 3;
        secondIsConcave = lerp(initial, -initial, alpha);

        if (elapsed >= 3) {
            clearInterval(intervalId); // Stop the interval
            secondIsConcave = -initial; // Reset the value
        }

    });
}

function updateSecondIsConcave(gl, secondIsConcaveLocation) {
    gl.uniform1i(secondIsConcaveLocation, secondIsConcave);
}